import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../notifications.dart';
import '../theme.dart';

final _nameRe = RegExp(r'^[a-z0-9_.]{3,20}$');

String authError(Object e) {
  if (e is FormatException) return e.message;
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
        'Incorrect username/email or password.',
      'email-already-in-use' => 'This email is already registered. Try signing in.',
      'weak-password' => 'Password is too weak (minimum 6 characters).',
      'invalid-email' => 'Invalid email format.',
      'network-request-failed' => 'No internet connection.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => e.message ?? e.code,
    };
  }
  if (e is FirebaseException) {
    return e.code == 'permission-denied'
        ? 'Firestore rules not updated. Please publish firestore.rules.'
        : (e.message ?? e.code);
  }
  return 'An error occurred: $e';
}

/// Sign out and cancel all reminders on this device.
Future<void> signOutAll() async {
  await AppNotifier.instance.cancelAll();
  await FirebaseAuth.instance.signOut();
}

/// Sign in with username or email.
Future<void> signIn(String id, String pass) async {
  var email = id.trim();
  if (email.isEmpty || pass.isEmpty) throw const FormatException('Enter your username/email and password.');
  if (!email.contains('@')) {
    final d = await FirebaseFirestore.instance.doc('usernames/${email.toLowerCase()}').get();
    if (!d.exists) throw const FormatException('Incorrect username/email or password.');
    email = d.get('email') as String;
  }
  await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
}

Future<void> resetPassword(String email) async {
  final mail = email.trim().toLowerCase();
  if (mail.isEmpty || !mail.contains('@')) {
    throw const FormatException('Please enter a valid email address.');
  }
  await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
}

Future<void> signUp(String username, String email, String pass) async {
  final name = username.trim().toLowerCase();
  final mail = email.trim().toLowerCase();
  if (!_nameRe.hasMatch(name)) {
    throw const FormatException('Username 3 to 20 characters: lowercase letters, numbers, dot, or underscore.');
  }
  if (!mail.contains('@')) throw const FormatException('Invalid email format.');
  final db = FirebaseFirestore.instance;
  if ((await db.doc('usernames/$name').get()).exists) throw const FormatException('Username is already taken.');
  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: mail, password: pass);
  try {
    await db.doc('usernames/$name').set({'uid': cred.user!.uid, 'email': mail});
    await cred.user!.updateDisplayName(name);
    await cred.user!.reload();
  } on FirebaseException catch (e) {
    await cred.user!.delete();
    throw FormatException(e.code == 'permission-denied' ? 'Username is already taken.' : 'Failed to save username: ${e.message}');
  }
}

void _toast(BuildContext c, String s) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.title, required this.subtitle, required this.children, this.back = false});
  final String title, subtitle;
  final List<Widget> children;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24), children: [
                if (back)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                  ),
                const Center(child: LuneraLogo(size: 88)),
                gap(16),
                Center(
                  child: Text(
                    title,
                    style: display(back ? 36 : 46, color: C.lavender),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!back) ...[
                  gap(4),
                  Center(
                    child: Text(
                      'Every Phase, Your Own.',
                      style: tagline(13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                gap(12),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .75),
                      ),
                  textAlign: TextAlign.center,
                ),
                gap(28),
                ...children,
              ]),
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
          labelText: 'Password',
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
    } catch (e) {
      if (mounted) _toast(context, authError(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _forgotPassword() async {
    final mailCtrl = TextEditingController(text: _id.text.contains('@') ? _id.text : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Forgot Password?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your registered email. We will send a password reset link to your email.'),
            gap(14),
            TextField(
              controller: mailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Send Email')),
        ],
      ),
    );

    if (ok == true && mounted) {
      try {
        await resetPassword(mailCtrl.text);
        if (mounted) {
          _toast(context, 'Reset link sent! Check your inbox or spam folder.');
        }
      } catch (e) {
        if (mounted) _toast(context, authError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
        title: 'Lunera',
        subtitle: 'Because every phase is part of your journey.',
        children: [
          TextField(
            controller: _id,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username or email'),
          ),
          gap(12),
          _PassField(controller: _p, onSubmit: _go),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _forgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          gap(12),
          pillButton(_busy ? 'Processing...' : 'Sign In', _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Don't have an account?"),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpPage())),
              child: const Text('Sign Up'),
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
        title: 'Create Account',
        subtitle: 'Username is used for sign in, email for account recovery.',
        children: [
          TextField(
            controller: _u,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Username', prefixText: '@', helperText: 'Lowercase letters, numbers, dot, or underscore (3 to 20)'),
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
          pillButton(_busy ? 'Processing...' : 'Sign Up', _go),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account?'),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Sign In')),
          ]),
        ],
      );
}
