import 'package:flutter/material.dart';
import '../lock.dart';
import '../theme.dart';
import 'auth.dart';

/// Membungkus aplikasi: terkunci saat dibuka, dan lagi setelah ditinggalkan cukup lama.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;
  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  late bool locked = Lock.instance.state.value.enabled;
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
      if (DateTime.now().difference(leftAt!) >= Duration(minutes: st.delayMin)) setState(() => locked = true);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (locked) Positioned.fill(child: LockScreen(onUnlock: () => setState(() => locked = false))),
      ]);
}

/// Papan angka dengan penanda 6 titik.
class PinPad extends StatelessWidget {
  const PinPad({super.key, required this.value, required this.onChanged, this.length = 6, this.onBio});
  final String value;
  final ValueChanged<String> onChanged;
  final int length;
  final VoidCallback? onBio;

  Widget _key(Widget child, VoidCallback? tap) => Padding(
        padding: const EdgeInsets.all(7),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Material(
            color: Colors.white.withValues(alpha: tap == null ? 0 : .1),
            shape: const CircleBorder(),
            child: InkWell(customBorder: const CircleBorder(), onTap: tap, child: Center(child: child)),
          ),
        ),
      );

  Widget _digit(int d) => _key(Text('$d', style: display(26, color: Colors.white)), value.length < length ? () => onChanged('$value$d') : null);

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < length; i++)
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: i < value.length ? 1 : .25)),
            ),
        ]),
        gap(24),
        for (final row in const [[1, 2, 3], [4, 5, 6], [7, 8, 9]]) Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) _digit(d)]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _key(const Icon(Icons.fingerprint_rounded, color: Colors.white), onBio),
          _digit(0),
          _key(const Icon(Icons.backspace_outlined, color: Colors.white), value.isEmpty ? null : () => onChanged(value.substring(0, value.length - 1))),
        ]),
      ]);
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
  int fails = 0;
  DateTime? until;

  @override
  void initState() {
    super.initState();
    if (Lock.instance.state.value.bio) WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
  }

  Future<void> _bio() async {
    if (await Lock.instance.authBio() && mounted) widget.onUnlock();
  }

  void _changed(String v) {
    if (until != null && DateTime.now().isBefore(until!)) {
      setState(() => msg = 'Tunggu sebentar sebelum mencoba lagi.');
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
    fails++;
    setState(() {
      pin = '';
      msg = 'PIN salah.';
      if (fails >= 5) {
        until = DateTime.now().add(const Duration(seconds: 30));
        fails = 0;
        msg = 'Terlalu banyak percobaan. Coba lagi dalam 30 detik.';
      }
    });
  }

  Future<void> _forgot() async {
    if (!await confirm(context, 'Keluar dari akun dan matikan kunci? Kamu perlu masuk lagi dengan kata sandi.', ok: 'Keluar')) return;
    await Lock.instance.disable();
    await signOutAll();
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          body: NightScene(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const MoonLogo(size: 64),
                    gap(10),
                    Text(appName, style: wordmark(30, color: Colors.white)),
                    gap(26),
                    Text('Masukkan PIN', style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 16)),
                    gap(18),
                    PinPad(value: pin, onChanged: _changed, onBio: Lock.instance.state.value.bio ? _bio : null),
                    SizedBox(height: 40, child: msg == null ? null : Center(child: Text(msg!, style: const TextStyle(color: Color(0xFFFFB3C7))))),
                    TextButton(onPressed: _forgot, child: const Text('Lupa PIN?', style: TextStyle(color: Colors.white70))),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
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
          msg = 'PIN salah.';
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
        msg = 'PIN tidak cocok. Ulangi dari awal.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          body: NightScene(
            child: SafeArea(
              child: Column(children: [
                Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white))),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(widget.create ? (first == null ? 'Buat PIN 6 angka' : 'Ulangi PIN') : widget.title, style: display(26, color: Colors.white)),
                        gap(24),
                        PinPad(value: pin, onChanged: _changed),
                        SizedBox(height: 40, child: msg == null ? null : Center(child: Text(msg!, style: const TextStyle(color: Color(0xFFFFB3C7))))),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Minta PIN yang berlaku; true jika benar.
Future<bool> askPin(BuildContext c, {String title = 'Masukkan PIN'}) async =>
    await Navigator.of(c).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _PinFlow(create: false, title: title))) ?? false;

/// PIN baru (dua kali ketik); null jika dibatalkan.
Future<String?> createPin(BuildContext c) =>
    Navigator.of(c).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _PinFlow(create: true, title: '')));

