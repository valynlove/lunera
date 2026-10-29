import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../lock.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widget_sync.dart';

final _nameRe = RegExp(r'^[a-z0-9_.]{3,20}$');

String authError(Object e) {
  if (e is FormatException) return e.message;
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
        'Username/email atau kata sandi salah.',
      'email-already-in-use' => 'Email ini sudah terdaftar. Coba masuk.',
      'weak-password' => 'Kata sandi terlalu lemah (minimal 6 karakter).',
      'invalid-email' => 'Format email tidak valid.',
      'network-request-failed' => 'Tidak ada koneksi internet.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      _ => e.message ?? e.code,
    };
  }
  if (e is FirebaseException) {
    return e.code == 'permission-denied'
        ? 'Aturan Firestore belum diperbarui. Tempel isi firestore.rules lalu Publish.'
        : (e.message ?? e.code);
  }
  return 'Terjadi kesalahan: $e';
}

/// Keluar dan batalkan semua pengingat di perangkat ini.
Future<void> signOutAll() async {
  await AppNotifier.instance.cancelAll();
  await WidgetSync.clear();
  await Lock.instance.clearLocal();
  await FirebaseAuth.instance.signOut();
}

Future<String?> _emailFor(String id) async {
  final v = id.trim();
  if (v.contains('@')) return v;
  final d = await FirebaseFirestore.instance.doc('usernames/${v.toLowerCase()}').get();
  return d.exists ? d.get('email') as String : null;
}

/// [id] boleh username atau email.
Future<void> signIn(String id, String pass) async {
  if (id.trim().isEmpty || pass.isEmpty) throw const FormatException('Isi username/email dan kata sandi.');
  final email = await _emailFor(id);
  if (email == null) throw const FormatException('Username/email atau kata sandi salah.');
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
  if (cred.user != null) {
    await Lock.instance.syncWithCloud(cred.user!.uid);
  }
}

/// Kirim email atur ulang kata sandi. Hasilnya sengaja sama, ada atau tidaknya akun,
/// supaya tidak membocorkan siapa saja yang terdaftar.
Future<void> resetPassword(String id) async {
  if (id.trim().isEmpty) throw const FormatException('Isi username atau email.');
  final email = await _emailFor(id);
  if (email == null) return;
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (e) {
    if (e.code != 'user-not-found') rethrow;
  }
}

Future<void> signUp(String username, String email, String pass) async {
  final name = username.trim().toLowerCase();
  final mail = email.trim().toLowerCase();
  if (!_nameRe.hasMatch(name)) {
    throw const FormatException('Username 3 sampai 20 karakter: huruf kecil, angka, titik, atau garis bawah.');
  }
  if (!mail.contains('@')) throw const FormatException('Format email tidak valid.');
  final db = FirebaseFirestore.instance;
  if ((await db.doc('usernames/$name').get()).exists) throw const FormatException('Username sudah dipakai.');
  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: mail, password: pass);
  try {
    await db.doc('usernames/$name').set({'uid': cred.user!.uid, 'email': mail});
    await cred.user!.updateDisplayName(name);
    await Lock.instance.syncWithCloud(cred.user!.uid);
  } on FirebaseException catch (e) {
    await cred.user!.delete();
    throw FormatException(e.code == 'permission-denied' ? 'Username sudah dipakai.' : 'Gagal menyimpan username: ${e.message}');
  }
}

void _toast(BuildContext c, String s) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

/// Halaman masuk/daftar selalu bertema malam, seperti layar pembuka.
class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.title, required this.subtitle, required this.children, this.back = false});
  final String title, subtitle;
  final List<Widget> children;
  final bool back;
  @override
  Widget build(BuildContext context) => Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          body: NightScene(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(28, 8, 28, 120), children: [
                    if (back)
                      Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)))
                    else
                      gap(40),
                    const MoonLogo(size: 56),
                    gap(14),
                    Text(title, style: display(36, color: Colors.white)),
                    gap(8),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .8))),
                    gap(26),
                    ...children,
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Layar pembuka: bulan, nama, dan ajakan mulai.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          body: NightScene(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 110),
                child: Column(children: [
                  const Spacer(flex: 2),
                  const MoonLogo(size: 120),
                  gap(18),
                  Text(appName, style: wordmark(48, color: Colors.white)),
                  gap(12),
                  Text(tagline, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 17)),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: pillButton('Mulai', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage()))),
                  ),
                  gap(8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Sudah punya akun?', style: TextStyle(color: Colors.white.withValues(alpha: .85))),
                    TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInPage())), child: const Text('Masuk')),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _PassField extends StatefulWidget {
  const _PassField({required this.controller, this.onSubmit});
  final TextEditingController controller;
  final VoidCallback? onSubmit;
  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool hide = true;
  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        obscureText: hide,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => widget.onSubmit?.call(),
        decoration: InputDecoration(
          labelText: 'Kata sandi',
          suffixIcon: IconButton(
            onPressed: () => setState(() => hide = !hide),
            icon: Icon(hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
          ),
        ),
      );
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInState();
}

class _SignInState extends State<SignInPage> {
  final _id = TextEditingController(), _p = TextEditingController();
  bool _busy = false;

  Future<void> _go() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await signIn(_id.text, _p.text);
      // AuthGate sudah menampilkan beranda di bawah halaman ini; tutup halaman masuk.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) _toast(context, authError(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _forgot() async {
    final c = TextEditingController(text: _id.text);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Atur ulang kata sandi'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Kami kirim tautan atur ulang ke email akunmu.'),
          gap(12),
          TextField(controller: c, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Username atau email')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Kirim tautan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await resetPassword(c.text);
      if (mounted) _toast(context, 'Jika akunnya ada, tautan atur ulang sudah dikirim ke emailnya. Cek juga folder spam.');
    } catch (e) {
      if (mounted) _toast(context, authError(e));
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        back: true,
        title: 'Selamat datang kembali',
        subtitle: 'Masuk untuk melanjutkan ritme terapimu.',
        children: [
          TextField(
            controller: _id,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username atau email'),
          ),
          gap(12),
          _PassField(controller: _p, onSubmit: _go),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: const Text('Lupa kata sandi?'))),
          gap(8),
          pillButton(_busy ? 'Memproses...' : 'Masuk', _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Belum punya akun?'),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignUpPage())),
              child: const Text('Daftar'),
            ),
          ]),
        ],
      );
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpState();
}

class _SignUpState extends State<SignUpPage> {
  final _u = TextEditingController(), _e = TextEditingController(), _p = TextEditingController();
  bool _busy = false;

  Future<void> _go() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await signUp(_u.text, _e.text, _p.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) _toast(context, authError(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        back: true,
        title: 'Buat akun',
        subtitle: 'Username dipakai untuk masuk, email untuk pemulihan akun.',
        children: [
          TextField(
            controller: _u,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username', prefixText: '@', helperText: 'Huruf kecil, angka, titik, garis bawah (3 sampai 20)'),
          ),
          gap(12),
          TextField(
            controller: _e,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          gap(12),
          _PassField(controller: _p, onSubmit: _go),
          gap(20),
          pillButton(_busy ? 'Memproses...' : 'Daftar', _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Sudah punya akun?'),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignInPage())),
              child: const Text('Masuk'),
            ),
          ]),
        ],
      );
}
