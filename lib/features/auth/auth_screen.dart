import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    username.dispose();
    super.dispose();
  }

  void continueToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DreamShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final signup = widget.createAccount;
    return Scaffold(
      body: DreamGradient(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const SizedBox(height: 20),
            IconButton(onPressed: () => Navigator.pop(context), alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back)),
            const SizedBox(height: 22),
            Text(signup ? 'Create your Dream Log' : 'Welcome back', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(signup ? 'Your dreams deserve a place to live.' : 'Your dream world is waiting.', style: const TextStyle(color: DreamColors.muted)),
            const SizedBox(height: 28),
            if (signup) ...[
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: username, decoration: const InputDecoration(labelText: 'Username', prefixText: '@')),
              const SizedBox(height: 12),
            ],
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: continueToApp,
              child: Text(signup ? 'Continue' : 'Sign in'),
            ),
            const SizedBox(height: 18),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or')), Expanded(child: Divider())]),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.apple), label: const Text('Continue with Apple')),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.g_mobiledata, size: 30), label: const Text('Continue with Google')),
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
