import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../lock.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widget_sync.dart';
import '../l10n.dart';

final _nameRe = RegExp(r'^[a-z0-9_.]{3,20}$');

String authError(Object e) {
  if (e is FormatException) return e.message;
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' =>
        tr('Wrong username/email or password.'),
      'email-already-in-use' =>
        tr('This email is already registered. Try logging in.'),
      'weak-password' => tr('Password is too weak (at least 6 characters).'),
      'invalid-email' => tr('Invalid email format.'),
      'network-request-failed' => tr('No internet connection.'),
      'too-many-requests' => tr('Too many attempts. Try again later.'),
      _ => e.message ?? e.code,
    };
  }
  if (e is FirebaseException) {
    return e.code == 'permission-denied'
        ? tr(
            'Firestore rules are out of date. Paste firestore.rules and publish.')
        : (e.message ?? e.code);
  }
  return tr('Something went wrong: {0}', [e]);
}

/// Keluar dan batalkan semua pengingat di perangkat ini.
Future<void> signOutAll() async {
  Lock.instance.sessionUnlocked = false;
  await AppNotifier.instance.cancelAll();
  await WidgetSync.clear();
  await FirebaseAuth.instance.signOut();
}

Future<String?> _emailFor(String id) async {
  final v = id.trim();
  if (v.contains('@')) return v;
  final d = await FirebaseFirestore.instance
      .doc('usernames/${v.toLowerCase()}')
      .get();
  return d.exists ? d.get('email') as String : null;
}

/// [id] boleh username atau email.
Future<void> signIn(String id, String pass) async {
  if (id.trim().isEmpty || pass.isEmpty) {
    throw FormatException(tr('Enter your username/email and password.'));
  }
  final email = await _emailFor(id);
  if (email == null) {
    throw FormatException(tr('Wrong username/email or password.'));
  }
  await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: pass);
}

/// Kirim email atur ulang kata sandi. Hasilnya sengaja sama, ada atau tidaknya akun,
/// supaya tidak membocorkan siapa saja yang terdaftar.
Future<void> resetPassword(String id) async {
  if (id.trim().isEmpty) {
    throw FormatException(tr('Enter your username or email.'));
  }
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
    throw FormatException(tr(
        'Username must be 3 to 20 characters: lowercase letters, numbers, dots, or underscores.'));
  }
  if (!mail.contains('@')) throw FormatException(tr('Invalid email format.'));
  final db = FirebaseFirestore.instance;
  if ((await db.doc('usernames/$name').get()).exists) {
    throw FormatException(tr('That username is taken.'));
  }
  final cred = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: mail, password: pass);
  try {
    await db.doc('usernames/$name').set({'uid': cred.user!.uid, 'email': mail});
    await cred.user!.updateDisplayName(name);
  } on FirebaseException catch (e) {
    await cred.user!.delete();
    throw FormatException(e.code == 'permission-denied'
        ? tr('That username is taken.')
        : tr('Could not save username: {0}', [e.message]));
  }
}

void _toast(BuildContext c, String s) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

/// Halaman masuk/daftar selalu bertema malam, seperti layar pembuka.
class _AuthShell extends StatelessWidget {
  const _AuthShell(
      {required this.title,
      required this.subtitle,
      required this.children,
      this.back = false});
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
                  child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 120),
                      children: [
                        if (back)
                          Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_rounded)))
                        else
                          gap(40),
                        const MoonLogo(size: 56),
                        gap(14),
                        Text(title, style: display(36, color: Colors.white)),
                        gap(8),
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: .8))),
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
                  const Align(
                      alignment: Alignment.centerRight, child: _LangToggle()),
                  const Spacer(flex: 2),
                  const MoonLogo(size: 120),
                  gap(18),
                  Text(appName, style: wordmark(48, color: Colors.white)),
                  gap(12),
                  Text(tagline,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: 17)),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: pillButton(
                        tr('Get started'),
                        () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const SignUpPage()))),
                  ),
                  gap(8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(tr('Already have an account?'),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: .85))),
                    TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignInPage())),
                        child: Text(tr('Log in'))),
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
          labelText: tr('Password'),
          suffixIcon: IconButton(
            onPressed: () => setState(() => hide = !hide),
            icon: Icon(
                hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
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
        title: Text(tr('Reset password')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('We\'ll send a reset link to your account email.')),
          gap(12),
          TextField(
              controller: c,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: tr('Username or email'))),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(tr('Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(tr('Send link'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await resetPassword(c.text);
      if (mounted) {
        _toast(context,
            tr('If the account exists, a reset link has been sent to its email. Check your spam folder too.'));
      }
    } catch (e) {
      if (mounted) _toast(context, authError(e));
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        back: true,
        title: tr('Welcome back'),
        subtitle: tr('Log in to continue your therapy rhythm.'),
        children: [
          TextField(
            controller: _id,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: tr('Username or email')),
          ),
          gap(12),
          _PassField(controller: _p, onSubmit: _go),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: _forgot, child: Text(tr('Forgot password?')))),
          gap(8),
          pillButton(_busy ? tr('Working...') : tr('Log in'), _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tr('Don\'t have an account?')),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignUpPage())),
              child: Text(tr('Sign up')),
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
  final _u = TextEditingController(),
      _e = TextEditingController(),
      _p = TextEditingController();
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
        title: tr('Create account'),
        subtitle: tr(
            'Your username is for logging in, and your email is for account recovery.'),
        children: [
          TextField(
            controller: _u,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                helperText: tr(
                    'Lowercase letters, numbers, dots, underscores (3 to 20)')),
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
          pillButton(_busy ? tr('Working...') : tr('Sign up'), _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tr('Already have an account?')),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignInPage())),
              child: Text(tr('Log in')),
            ),
          ]),
        ],
      );
}

/// Pilihan bahasa di layar Mulai: EN | ID.
class _LangToggle extends StatelessWidget {
  const _LangToggle();
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        for (final l in const [('en', 'EN'), ('id', 'ID')])
          TextButton(
            onPressed: () => L10n.set(l.$1),
            child: Text(
              l.$2,
              style: TextStyle(
                  color: Colors.white
                      .withValues(alpha: L10n.code == l.$1 ? 1 : .55),
                  fontWeight:
                      L10n.code == l.$1 ? FontWeight.w800 : FontWeight.w500),
            ),
          ),
      ]);
}
