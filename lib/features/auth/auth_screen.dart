import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';
import '../shell/dream_shell.dart';

class AuthScreen extends StatefulWidget {
  final bool createAccount;
  const AuthScreen({super.key, required this.createAccount});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final username = TextEditingController();
  final _auth = FirebaseAuthService();
  bool loading = false;

  @override
  void dispose() {
    email.dispose(); password.dispose(); name.dispose(); username.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty ||
        (widget.createAccount && (name.text.trim().isEmpty || username.text.trim().isEmpty))) {
      _message('Please complete all fields.');
      return;
    }
    setState(() => loading = true);
    try {
      if (widget.createAccount) {
        await _auth.signUp(email: email.text, password: password.text, displayName: name.text, username: username.text);
      } else {
        await _auth.signIn(email: email.text, password: password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DreamShell()), (_) => false);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Authentication failed.');
    } catch (e) {
      _message(e.toString().replaceFirst('Bad state: ', '').replaceFirst('Invalid argument(s): ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    final signup = widget.createAccount;
    return Scaffold(
      body: DreamGradient(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 20),
            IconButton(onPressed: loading ? null : () => Navigator.pop(context), alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back)),
            const SizedBox(height: 22),
            Text(signup ? 'Create your Dream Log' : 'Welcome back', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(signup ? 'Your dreams deserve a place to live.' : 'Your dream world is waiting.', style: const TextStyle(color: DreamColors.muted)),
            const SizedBox(height: 28),
            if (signup) ...[
              TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: username, textInputAction: TextInputAction.next, autocorrect: false, decoration: const InputDecoration(labelText: 'Username', prefixText: '@')),
              const SizedBox(height: 12),
            ],
            TextField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autocorrect: false, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, onSubmitted: (_) => loading ? null : submit(), decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: loading ? null : submit,
              child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(signup ? 'Create account' : 'Sign in'),
            ),
            const SizedBox(height: 18),
            const Text('Google and Apple sign-in are coming next.', textAlign: TextAlign.center, style: TextStyle(color: DreamColors.muted, fontSize: 12)),
            if (signup) const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('By continuing, you agree to our Terms and Privacy Policy.', textAlign: TextAlign.center, style: TextStyle(color: DreamColors.muted, fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}
