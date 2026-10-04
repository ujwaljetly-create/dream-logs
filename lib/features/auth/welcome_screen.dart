import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DreamGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [DreamColors.violet, DreamColors.blue]),
                  boxShadow: [BoxShadow(color: DreamColors.violet.withValues(alpha: .35), blurRadius: 50)],
                ),
                child: const Text('🌙', style: TextStyle(fontSize: 58)),
              ),
              const SizedBox(height: 30),
              Text('Dream Logs', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              const Text(
                'Remember it. Recreate it. Share the world you saw while you slept.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DreamColors.muted, fontSize: 17, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(createAccount: true))),
                  child: const Text('Create your Dream Log'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(createAccount: false))),
                child: const Text('I already have an account'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
