import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../lock.dart';
import '../theme.dart';
import 'auth.dart';
import '../l10n.dart';

/// Membungkus aplikasi: terkunci saat dibuka, dan lagi setelah ditinggalkan cukup lama.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool locked = Lock.instance.state.value.enabled && !Lock.instance.sessionUnlocked;
  DateTime? leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Lock.instance.state.addListener(_onState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Lock.instance.state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (!Lock.instance.state.value.enabled && locked) setState(() => locked = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final st = Lock.instance.state.value;
    if (s == AppLifecycleState.paused) leftAt = DateTime.now();
    if (s == AppLifecycleState.resumed && st.enabled && leftAt != null && !locked) {
      if (DateTime.now().difference(leftAt!) >= Duration(minutes: st.delayMin)) {
        Lock.instance.sessionUnlocked = false;
        setState(() => locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (locked) Positioned.fill(child: LockScreen(
            onUnlock: () {
              Lock.instance.sessionUnlocked = true;
              setState(() => locked = false);
            },
          )),
      ]);
}

/// Papan angka dengan penanda 6 titik bertema celestial.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    this.length = 6,
    this.onBio,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int length;
  final VoidCallback? onBio;

  Widget _key({
    required Widget child,
    VoidCallback? tap,
    Color? highlightColor,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: SizedBox(
          width: 74,
          height: 74,
          child: Material(
            color: tap == null
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
            shape: CircleBorder(
              side: BorderSide(
                color: tap == null
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
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

  static const _subLetters = ['', '', 'ABC', 'DEF', 'GHI', 'JKL', 'MNO', 'PQRS', 'TUV', 'WXYZ'];

  Widget _digit(int d) {
    final canTap = value.length < length;
    final letters = d >= 0 && d < _subLetters.length ? _subLetters[d] : '';
    return _key(
      tap: canTap ? () => onChanged('$value$d') : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$d',
            style: display(28, color: Colors.white, weight: FontWeight.w600),
          ),
          if (letters.isNotEmpty)
            Text(
              letters,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indikator 6 Titik PIN Bersinar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: i < value.length ? 16 : 14,
                  height: i < value.length ? 16 : 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < value.length
                        ? Pastel.lilac
                        : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: i < value.length
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      width: i < value.length ? 1.5 : 1.0,
                    ),
                    boxShadow: i < value.length
                        ? [
                            BoxShadow(
                              color: Pastel.lilac.withValues(alpha: 0.65),
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
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: onBio != null ? Pastel.mint : Colors.transparent,
                  size: 30,
                ),
              ),
              _digit(0),
              _key(
                tap: value.isEmpty ? null : () => onChanged(value.substring(0, value.length - 1)),
                child: Icon(
                  Icons.backspace_outlined,
                  color: value.isNotEmpty
                      ? Colors.white.withValues(alpha: 0.85)
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

  @override
  void initState() {
    super.initState();
    if (Lock.instance.isLockedOut) {
      msg = tr('Wait a moment before trying again.');
    }
    if (Lock.instance.state.value.bio) WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
  }

  Future<void> _bio() async {
    if (await Lock.instance.authBio() && mounted) widget.onUnlock();
  }

  void _changed(String v) {
    if (Lock.instance.isLockedOut) {
      setState(() => msg = tr('Wait a moment before trying again.'));
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
      msg = Lock.instance.isLockedOut
          ? tr('Too many attempts. Try again in 30 seconds.')
          : tr('Wrong PIN.');
    });
  }

  Future<void> _forgot() async {
    if (!await confirm(context, tr('Log out and turn off the lock? You\'ll need to log in again with your password.'), ok: tr('Log out'))) return;
    await Lock.instance.disable();
    await signOutAll();
  }

  @override
  Widget build(BuildContext context) {
    if (Lock.instance.state.value.decoyCalculator) {
      return Theme(
        data: buildTheme(Brightness.dark),
        child: _DecoyCalculatorView(
          onUnlock: widget.onUnlock,
          onForgot: _forgot,
          onBio: Lock.instance.state.value.bio ? _bio : null,
        ),
      );
    }

    return Theme(
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
                          const Icon(Icons.lock_rounded, size: 14, color: Pastel.lilac),
                          const SizedBox(width: 6),
                          Text(
                            tr('Enter PIN'),
                            style: TextStyle(
                              color: Pastel.mist.withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    gap(28),
                    PinPad(
                      value: pin,
                      onChanged: _changed,
                      onBio: Lock.instance.state.value.bio ? _bio : null,
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
                                    const Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFFF8A80)),
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
                      icon: const Icon(Icons.help_outline_rounded, size: 16, color: Colors.white60),
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
    );
  }
}

class _DecoyCalculatorView extends StatefulWidget {
  const _DecoyCalculatorView({
    required this.onUnlock,
    required this.onForgot,
    this.onBio,
  });

  final VoidCallback onUnlock;
  final VoidCallback onForgot;
  final VoidCallback? onBio;

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
                      icon: const Icon(Icons.fingerprint_rounded, color: Colors.white70),
                      onPressed: widget.onBio,
                      tooltip: tr('Fingerprint or face'),
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
                        icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 20),
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

  void _changed(String v) {
    if (!widget.create && Lock.instance.isLockedOut) {
      setState(() => msg = tr('Wait a moment before trying again.'));
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
          msg = Lock.instance.isLockedOut
              ? tr('Too many attempts. Try again in 30 seconds.')
              : tr('Wrong PIN.');
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
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                              child: const Icon(Icons.dialpad_rounded, size: 36, color: Pastel.lilac),
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
                                            const Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFFF8A80)),
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
