import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n.dart';
import '../lock.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widget_sync.dart';

final _nameRe = RegExp(r'^[a-z0-9_.]{3,20}$');

String authError(Object e) {
  if (e is FormatException) return trG(e.message);
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
        trG('Incorrect username/email or password.'),
      'email-already-in-use' => trG('This email is already in use. Try signing in.'),
      'weak-password' => trG('Password is too weak (minimum 6 characters).'),
      'invalid-email' => trG('Invalid email format.'),
      'network-request-failed' => trG('No internet connection.'),
      'too-many-requests' => trG('Too many attempts. Please try again later.'),
      _ => e.message ?? e.code,
    };
  }
  if (e is FirebaseException) {
    return e.code == 'permission-denied'
        ? trG('Firestore rules not updated. Paste firestore.rules and Publish.')
        : (e.message ?? e.code);
  }
  return '${trG('An error occurred')}: $e';
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
  if (id.trim().isEmpty || pass.isEmpty) throw const FormatException('Fill in username/email and password.');
  final email = await _emailFor(id);
  if (email == null) throw const FormatException('Incorrect username/email or password.');
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
  if (cred.user != null) {
    await Lock.instance.syncWithCloud(cred.user!.uid);
  }
}

/// Kirim email atur ulang kata sandi. Hasilnya sengaja sama, ada atau tidaknya akun,
/// supaya tidak membocorkan siapa saja yang terdaftar.
Future<void> resetPassword(String id) async {
  if (id.trim().isEmpty) throw const FormatException('Fill in username or email.');
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
    throw const FormatException('Username must be 3-20 characters: lowercase letters, numbers, dots, or underscores.');
  }
  if (!mail.contains('@')) throw const FormatException('Invalid email format.');
  final db = FirebaseFirestore.instance;
  if ((await db.doc('usernames/$name').get()).exists) throw const FormatException('Username is already taken.');
  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: mail, password: pass);
  try {
    await db.doc('usernames/$name').set({'uid': cred.user!.uid, 'email': mail});
    await cred.user!.updateDisplayName(name);
    await Lock.instance.syncWithCloud(cred.user!.uid);
  } on FirebaseException catch (e) {
    await cred.user!.delete();
    throw FormatException(e.code == 'permission-denied' ? 'Username is already taken.' : 'Failed to save username: ${e.message}');
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
          body: LakeScene(
            moon: false,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 110),
                child: Column(children: [
                  const Spacer(flex: 2),
                  const MoonLogo(size: 120),
                  gap(18),
                  Text(appName, style: wordmark(48, color: Colors.white)),
                  gap(12),
                  Text(context.tr(tagline), style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 17)),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: pillButton(context.tr('Get Started'), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage()))),
                  ),
                  gap(8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(context.tr('Already have an account?'), style: TextStyle(color: Colors.white.withValues(alpha: .85))),
                    TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInPage())), child: Text(context.tr('Sign in'))),
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
          labelText: context.tr('Password'),
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
        title: Text(context.tr('Reset password')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.tr('We will send a reset link to your account email.')),
          gap(12),
          TextField(controller: c, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: context.tr('Username or email'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(context.tr('Send link'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await resetPassword(c.text);
      if (mounted) _toast(context, context.tr('If the account exists, a reset link was sent to its email. Check spam folder as well.'));
    } catch (e) {
      if (mounted) _toast(context, authError(e));
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        back: true,
        title: context.tr('Welcome back'),
        subtitle: context.tr('Sign in to continue your therapy rhythm.'),
        children: [
          TextField(
            controller: _id,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.tr('Username or email')),
          ),
          gap(12),
          _PassField(controller: _p, onSubmit: _go),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: Text(context.tr('Forgot password?')))),
          gap(8),
          pillButton(_busy ? context.tr('Processing...') : context.tr('Sign in'), _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(context.tr("Don't have an account?")),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignUpPage())),
              child: Text(context.tr('Sign up')),
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
        title: context.tr('Create account'),
        subtitle: context.tr('Username is used to sign in, email for account recovery.'),
        children: [
          TextField(
            controller: _u,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.tr('Username'), prefixText: '@', helperText: context.tr('Lowercase letters, numbers, dots, underscores (3-20)')),
          ),
          gap(12),
          TextField(
            controller: _e,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.tr('Email')),
          ),
          gap(12),
          _PassField(controller: _p, onSubmit: _go),
          gap(20),
          pillButton(_busy ? context.tr('Processing...') : context.tr('Sign up'), _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(context.tr('Already have an account?')),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignInPage())),
              child: Text(context.tr('Sign in')),
            ),
          ]),
        ],
      );
}
