import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../lock.dart';
import '../theme.dart';
import 'auth.dart';
import 'splash.dart';
import '../l10n.dart';

/// Membungkus aplikasi: memverifikasi kunci lokal & cloud sebelum merender [child],
/// dan mengunci ulang setelah ditinggalkan melewati batas waktu.
class LockGate extends StatefulWidget {
  const LockGate({
    super.key,
    required this.child,
    this.uid,
    this.syncCloud,
  });

  final Widget child;
  final String? uid;
  final Future<void> Function(String uid)? syncCloud;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  String? get _effectiveUid {
    if (widget.uid != null) return widget.uid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  late bool locked = Lock.instance.state.value.enabled && !Lock.instance.sessionUnlocked;
  bool _resolvingUser = false;
  late bool checkingLock = !Lock.instance.sessionUnlocked &&
      !locked &&
      _effectiveUid != null &&
      (widget.syncCloud != null || !Lock.instance.hasSyncedFor(_effectiveUid!));
  DateTime? leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Lock.instance.state.addListener(_onState);
    _resolveUserAndSync(fromInit: true);
  }

  @override
  void didUpdateWidget(covariant LockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _resolveUserAndSync(fromInit: false);
    }
  }

  void _resolveUserAndSync({required bool fromInit}) {
    final targetUid = _effectiveUid;
    if (Lock.instance.isInitialized && targetUid != null && !Lock.instance.isLoadedFor(targetUid)) {
      _resolvingUser = true;
      locked = true;
      Lock.instance.isLocked.value = true;
      if (!fromInit && mounted) setState(() {});
      Lock.instance.ensureLocalLoaded(targetUid).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _resolvingUser = false;
          locked = Lock.instance.state.value.enabled && !Lock.instance.sessionUnlocked;
          Lock.instance.isLocked.value = locked;
          if (!locked && !Lock.instance.sessionUnlocked &&
              (widget.syncCloud != null || !Lock.instance.hasSyncedFor(targetUid))) {
            checkingLock = true;
          }
        });
        _runInitialCloudSync();
      });
    } else {
      _resolvingUser = false;
      locked = Lock.instance.state.value.enabled && !Lock.instance.sessionUnlocked;
      Lock.instance.isLocked.value = locked;
      if (!fromInit && targetUid != null && !Lock.instance.sessionUnlocked && !locked &&
          (widget.syncCloud != null || !Lock.instance.hasSyncedFor(targetUid))) {
        checkingLock = true;
      }
      if (!fromInit && mounted) setState(() {});
      _runInitialCloudSync();
    }
  }

  Future<void> _runInitialCloudSync() async {
    final uid = _effectiveUid;
    if (uid == null) {
      if (checkingLock && mounted) {
        setState(() => checkingLock = false);
      }
      return;
    }
    try {
      final fn = widget.syncCloud ?? Lock.instance.syncWithCloud;
      await fn(uid);
    } catch (e) {
      debugPrint('LockGate cloud sync error: $e');
    } finally {
      if (mounted) {
        setState(() {
          checkingLock = false;
          if (!Lock.instance.signingOut && !Lock.instance.isLockSuppressed) {
            locked = Lock.instance.state.value.enabled && !Lock.instance.sessionUnlocked;
            Lock.instance.isLocked.value = locked;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Lock.instance.state.removeListener(_onState);
    super.dispose();
  }

  void _engageLock() {
    try {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    } catch (_) {}
    Lock.instance.isLocked.value = true;
    setState(() => locked = true);
  }

  void _onState() {
    if (!mounted || Lock.instance.signingOut || _resolvingUser) return;
    final enabled = Lock.instance.state.value.enabled;
    if (!enabled && locked) {
      Lock.instance.consumeAutoLockOnEnable();
      Lock.instance.isLocked.value = false;
      setState(() => locked = false);
    } else if (enabled &&
        !Lock.instance.sessionUnlocked &&
        !locked &&
        !Lock.instance.isLockSuppressed &&
        !Lock.instance.isAuthenticating) {
      Lock.instance.consumeAutoLockOnEnable();
      _engageLock();
    } else if (enabled &&
        !locked &&
        !Lock.instance.isLockSuppressed &&
        !Lock.instance.isAuthenticating &&
        Lock.instance.consumeAutoLockOnEnable()) {
      Lock.instance.sessionUnlocked = false;
      _engageLock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final st = Lock.instance.state.value;
    if (s == AppLifecycleState.paused) {
      if (Lock.instance.isLockSuppressed || Lock.instance.isAuthenticating || Lock.instance.signingOut) {
        leftAt = null;
        return;
      }
      leftAt = DateTime.now();
    }
    if (s == AppLifecycleState.resumed) {
      final previousLeftAt = leftAt;
      leftAt = null;
      if (locked) {
        Lock.instance.refreshBiometricSupport();
        return;
      }
      if (!st.enabled || _resolvingUser) return;
      if (Lock.instance.isLockSuppressed || Lock.instance.isAuthenticating || Lock.instance.signingOut) {
        return;
      }
      if (previousLeftAt == null) return;
      final requiredDelay = st.delayMin == 0 ? const Duration(seconds: 3) : Duration(minutes: st.delayMin);
      if (DateTime.now().difference(previousLeftAt) >= requiredDelay) {
        Lock.instance.sessionUnlocked = false;
        _engageLock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvingUser || checkingLock) {
      return const SplashPage();
    }
    if (locked || Lock.instance.signingOut) {
      return LockScreen(
        onUnlock: () {
          Lock.instance.sessionUnlocked = true;
          Lock.instance.isLocked.value = false;
          setState(() {
            locked = false;
            checkingLock = false;
          });
        },
      );
    }
    return widget.child;
  }
}

/// Papan angka dengan penanda 6 titik bertema celestial (terinspirasi dari konsep Wall o' Pay).
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 6,
    this.onBio,
    this.biometricIcon = LucideIcons.fingerprintPattern,
    this.biometricTooltip,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int length;
  final VoidCallback? onBio;
  final IconData biometricIcon;
  final String? biometricTooltip;

  Widget _key({
    required Widget child,
    VoidCallback? tap,
    Color? highlightColor,
  }) {
    const shape = CircleBorder();
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Colors.white.withValues(alpha: tap == null ? 0 : 0.08),
          shape: CircleBorder(
            side: BorderSide(
              color: tap == null
                  ? Colors.transparent
                  : C.lavender.withValues(alpha: 0.22),
              width: 1.0,
            ),
          ),
          child: InkWell(
            customBorder: shape,
            splashColor: (highlightColor ?? Pastel.lilac).withValues(alpha: 0.25),
            highlightColor: (highlightColor ?? Pastel.lilac).withValues(alpha: 0.15),
            onTap: tap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    tap();
                  },
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _digit(int d) {
    final canTap = value.length < length;
    return _key(
      tap: canTap ? () => onChanged('$value$d') : null,
      child: Text(
        '$d',
        style: display(26, color: Colors.white, weight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indikator 6 Titik PIN Bersinar ala Wall o' Pay
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: ShapeDecoration(
                    color: i < value.length
                        ? Pastel.lilac
                        : Colors.white.withValues(alpha: 0.20),
                    shape: const CircleBorder(),
                    shadows: i < value.length
                        ? [
                            BoxShadow(
                              color: Pastel.lilac.withValues(alpha: 0.55),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
            ],
          ),
          gap(28),
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9]
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final d in row) _digit(d)],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _key(
                tap: onBio,
                highlightColor: Pastel.mint,
                child: Tooltip(
                  message: biometricTooltip ?? tr('Unlock with biometric'),
                  child: Icon(
                    biometricIcon,
                    color: onBio != null ? Pastel.mint : Colors.transparent,
                    size: 28,
                  ),
                ),
              ),
              _digit(0),
              _key(
                tap: value.isEmpty ? null : () => onChanged(value.substring(0, value.length - 1)),
                child: Icon(
                  LucideIcons.delete,
                  color: value.isNotEmpty
                      ? Colors.white.withValues(alpha: 0.90)
                      : Colors.transparent,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      );
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlock});
  final VoidCallback onUnlock;
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String pin = '';
  String? msg;
  bool _bioRunning = false;
  bool _signingOut = false;

  String _lockoutMessage() {
    final sec = Lock.instance.remainingLockoutSeconds;
    if (sec > 0) {
      return tr('Please wait {0}s before trying again.', [sec]);
    }
    return tr('Wait a moment before trying again.');
  }

  @override
  void initState() {
    super.initState();
    if (Lock.instance.isLockedOut) {
      msg = _lockoutMessage();
    }
    if (Lock.instance.state.value.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
    }
  }

  Future<void> _bio() async {
    if (_bioRunning || _signingOut || Lock.instance.signingOut || !mounted) return;
    if (Lock.instance.isLockedOut) {
      setState(() => msg = _lockoutMessage());
      return;
    }
    _bioRunning = true;
    try {
      if (await Lock.instance.authBio() && mounted && !_signingOut) widget.onUnlock();
    } finally {
      if (mounted) _bioRunning = false;
    }
  }

  void _changed(String v) {
    if (_signingOut || Lock.instance.signingOut) return;
    if (Lock.instance.isLockedOut) {
      setState(() => msg = _lockoutMessage());
      return;
    }
    setState(() {
      pin = v;
      msg = null;
    });
    if (v.length < 6) return;
    if (Lock.instance.verify(v)) {
      widget.onUnlock();
      return;
    }
    setState(() {
      pin = '';
      msg = Lock.instance.isLockedOut ? _lockoutMessage() : tr('Wrong PIN.');
    });
  }

  Future<void> _forgot() async {
    if (_signingOut) return;
    if (!await confirm(
      context,
      tr('Log out and remove the lock from this device? Cloud lock protection remains active on your account.'),
      ok: tr('Log out'),
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _signingOut = true);
    Lock.instance.signingOut = true;
    try {
      await Lock.instance.clearLocal();
      await signOutAll();
    } finally {
      Lock.instance.signingOut = false;
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLockState>(
      valueListenable: Lock.instance.state,
      builder: (context, st, _) {
        final bioIcon = st.isFaceOnly ? LucideIcons.scanFace : LucideIcons.fingerprintPattern;
        final bioTooltip = st.isFaceOnly
            ? tr('Face Unlock')
            : st.isFingerprintOnly
                ? tr('Fingerprint Unlock')
                : tr('Biometric Unlock');

        if (st.decoyCalculator) {
          return PopScope(
            canPop: false,
            child: Theme(
              data: buildTheme(Brightness.dark),
              child: _DecoyCalculatorView(
                onUnlock: widget.onUnlock,
                onForgot: _forgot,
                onBio: st.biometricEnabled ? _bio : null,
                biometricIcon: bioIcon,
                biometricTooltip: bioTooltip,
              ),
            ),
          );
        }

        final promptText = !st.biometricEnabled
            ? tr('Enter PIN')
            : st.isFaceOnly
                ? tr('Enter 6-digit PIN or use Face Unlock')
                : st.isFingerprintOnly
                    ? tr('Enter 6-digit PIN or scan fingerprint')
                    : tr('Enter PIN');

        return PopScope(
          canPop: false,
          child: Theme(
            data: buildTheme(Brightness.dark),
            child: Scaffold(
              body: AuthScene(
                darken: true,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Pastel.lilac.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Pastel.lilac.withValues(alpha: 0.20),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const MoonLogo(size: 64),
                          ),
                          gap(12),
                          Text(appName, style: wordmark(32, color: Colors.white)),
                          gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.lock, size: 16, color: C.iconActive),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    promptText,
                                    style: TextStyle(
                                      color: Pastel.mist.withValues(alpha: 0.95),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          gap(28),
                          PinPad(
                            value: pin,
                            onChanged: _changed,
                            onBio: st.biometricEnabled ? _bio : null,
                            biometricIcon: bioIcon,
                            biometricTooltip: bioTooltip,
                          ),
                          gap(8),
                          SizedBox(
                            height: 38,
                            child: msg == null
                                ? null
                                : Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33FF5722),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0x66FF5722)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.circleAlert, size: 16, color: Color(0xFFFF8A80)),
                                          const SizedBox(width: 6),
                                          Text(
                                            msg!,
                                            style: const TextStyle(
                                              color: Color(0xFFFFCDD2),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                          gap(10),
                          TextButton.icon(
                            onPressed: _forgot,
                            icon: const Icon(LucideIcons.circleHelp, size: 16, color: C.iconDefault),
                            label: Text(
                              tr('Forgot PIN?'),
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DecoyCalculatorView extends StatefulWidget {
  const _DecoyCalculatorView({
    required this.onUnlock,
    required this.onForgot,
    this.onBio,
    this.biometricIcon = LucideIcons.fingerprintPattern,
    this.biometricTooltip,
  });

  final VoidCallback onUnlock;
  final VoidCallback onForgot;
  final VoidCallback? onBio;
  final IconData biometricIcon;
  final String? biometricTooltip;

  @override
  State<_DecoyCalculatorView> createState() => _DecoyCalculatorViewState();
}

class _DecoyCalculatorViewState extends State<_DecoyCalculatorView> {
  String _expression = '';
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldReset = false;
  String _pinBuffer = '';

  void _onDigit(String d) {
    setState(() {
      if (_display == '0' || _shouldReset) {
        _display = d;
        _shouldReset = false;
      } else if (_display.length < 14) {
        _display += d;
      }

      _pinBuffer += d;
      if (_pinBuffer.length > 6) {
        _pinBuffer = _pinBuffer.substring(_pinBuffer.length - 6);
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (_shouldReset) {
        _display = '0.';
        _shouldReset = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
      if (_pinBuffer.isNotEmpty) {
        _pinBuffer = _pinBuffer.substring(0, _pinBuffer.length - 1);
      }
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _shouldReset = false;
      _pinBuffer = '';
    });
  }

  void _onSign() {
    setState(() {
      if (_display != '0') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    });
  }

  void _onPercent() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      _display = _fmt(val / 100);
    });
  }

  void _onOp(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '$_display $op';
      _shouldReset = true;
      _pinBuffer = '';
    });
  }

  void _onEquals() {
    // Secret Unlock Check: periksa kandidat 6-digit PIN hanya saat tidak ada operator aktif,
    // menggunakan pembatasan percobaan persisten tanpa membongkar samaran kalkulator.
    final candidate = decoyPinCandidate(display: _display, pinBuffer: _pinBuffer, operator: _operator);
    if (candidate != null) {
      if (Lock.instance.verify(candidate)) {
        widget.onUnlock();
        return;
      }
      setState(() {
        _shouldReset = true;
        _pinBuffer = '';
      });
      return;
    }

    // Perhitungan kalkulator biasa jika bukan PIN
    if (_firstOperand != null && _operator != null) {
      final num2 = double.tryParse(_display) ?? 0;
      double result = 0;
      switch (_operator) {
        case '+':
          result = _firstOperand! + num2;
          break;
        case '−':
          result = _firstOperand! - num2;
          break;
        case '×':
          result = _firstOperand! * num2;
          break;
        case '÷':
          result = num2 != 0 ? _firstOperand! / num2 : 0;
          break;
      }
      setState(() {
        _expression = '$_firstOperand $_operator $_display =';
        _display = _fmt(result);
        _firstOperand = null;
        _operator = null;
        _shouldReset = true;
        _pinBuffer = '';
      });
    }
  }

  String _fmt(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Widget _calcButton({
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Color? color,
    Color? textColor,
    Widget? icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Material(
            color: color ?? Colors.white.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              onLongPress: onLongPress,
              child: Center(
                child: icon ??
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.white,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      body: SafeArea(
        child: Column(
          children: [
            // Top stealth header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    tr('Calculator'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onBio != null)
                    IconButton(
                      icon: Icon(widget.biometricIcon, color: Colors.white70),
                      onPressed: widget.onBio,
                      tooltip: widget.biometricTooltip ?? tr('Fingerprint or face'),
                    ),
                ],
              ),
            ),
            const Spacer(),
            // Calculator Display Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 24,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _expression,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _display,
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Keypad Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _calcButton(
                        label: 'C',
                        onTap: _onClear,
                        onLongPress: widget.onForgot,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _calcButton(
                        label: '±',
                        onTap: _onSign,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _calcButton(
                        label: '%',
                        onTap: _onPercent,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _calcButton(
                        label: '÷',
                        onTap: () => _onOp('÷'),
                        color: C.peony.withValues(alpha: 0.75),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton(label: '7', onTap: () => _onDigit('7')),
                      _calcButton(label: '8', onTap: () => _onDigit('8')),
                      _calcButton(label: '9', onTap: () => _onDigit('9')),
                      _calcButton(
                        label: '×',
                        onTap: () => _onOp('×'),
                        color: C.peony.withValues(alpha: 0.75),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton(label: '4', onTap: () => _onDigit('4')),
                      _calcButton(label: '5', onTap: () => _onDigit('5')),
                      _calcButton(label: '6', onTap: () => _onDigit('6')),
                      _calcButton(
                        label: '−',
                        onTap: () => _onOp('−'),
                        color: C.peony.withValues(alpha: 0.75),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton(label: '1', onTap: () => _onDigit('1')),
                      _calcButton(label: '2', onTap: () => _onDigit('2')),
                      _calcButton(label: '3', onTap: () => _onDigit('3')),
                      _calcButton(
                        label: '+',
                        onTap: () => _onOp('+'),
                        color: C.peony.withValues(alpha: 0.75),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _calcButton(label: '0', onTap: () => _onDigit('0')),
                      _calcButton(label: '.', onTap: _onDecimal),
                      _calcButton(
                        label: '⌫',
                        icon: const Icon(LucideIcons.delete, color: Colors.white, size: 20),
                        onTap: _onBackspace,
                      ),
                      _calcButton(
                        label: '=',
                        onTap: _onEquals,
                        color: C.peony,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.onForgot,
                child: Text(
                  tr('Forgot PIN?'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PinFlow extends StatefulWidget {
  const _PinFlow({required this.create, required this.title});
  final bool create;
  final String title;
  @override
  State<_PinFlow> createState() => _PinFlowState();
}

class _PinFlowState extends State<_PinFlow> {
  String pin = '';
  String? first, msg;

  String _lockoutMessage() {
    final sec = Lock.instance.remainingLockoutSeconds;
    if (sec > 0) {
      return tr('Please wait {0}s before trying again.', [sec]);
    }
    return tr('Wait a moment before trying again.');
  }

  void _changed(String v) {
    if (!widget.create && Lock.instance.isLockedOut) {
      setState(() => msg = _lockoutMessage());
      return;
    }
    setState(() {
      pin = v;
      msg = null;
    });
    if (v.length < 6) return;
    if (!widget.create) {
      if (Lock.instance.verify(v)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          pin = '';
          msg = Lock.instance.isLockedOut ? _lockoutMessage() : tr('Wrong PIN.');
        });
      }
    } else if (first == null) {
      setState(() {
        first = v;
        pin = '';
      });
    } else if (first == v) {
      Navigator.pop(context, v);
    } else {
      setState(() {
        first = null;
        pin = '';
        msg = tr('PINs don\'t match. Start again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          body: AuthScene(
            darken: true,
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Pastel.lilac.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(LucideIcons.grid, size: 24, color: C.iconActive),
                            ),
                            gap(16),
                            Text(
                              widget.create
                                  ? (first == null ? tr('Create a 6-digit PIN') : tr('Repeat PIN'))
                                  : widget.title,
                              textAlign: TextAlign.center,
                              style: display(26, color: Colors.white),
                            ),
                            gap(28),
                            PinPad(value: pin, onChanged: _changed),
                            gap(8),
                            SizedBox(
                              height: 38,
                              child: msg == null
                                  ? null
                                  : Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0x33FF5722),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0x66FF5722)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.circleAlert, size: 16, color: Color(0xFFFF8A80)),
                                            const SizedBox(width: 6),
                                            Text(
                                              msg!,
                                              style: const TextStyle(
                                                color: Color(0xFFFFCDD2),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Minta PIN yang berlaku; true jika benar.
Future<bool> askPin(BuildContext c, {String? title}) async =>
    await Navigator.of(c).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _PinFlow(create: false, title: title ?? tr('Enter PIN')))) ?? false;

/// PIN baru (dua kali ketik); null jika dibatalkan.
Future<String?> createPin(BuildContext c) =>
    Navigator.of(c).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _PinFlow(create: true, title: '')));
