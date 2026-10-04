import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DreamGradient extends StatelessWidget {
  final Widget child;
  const DreamGradient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.4,
          colors: [Color(0xFF32205F), DreamColors.night],
        ),
      ),
      child: child,
    );
  }
}
