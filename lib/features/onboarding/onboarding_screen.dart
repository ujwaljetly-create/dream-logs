import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  final pages = const [
    ('Turn dreams into stories', 'Describe what you remember and AI will recreate your dream as a visual story.', '✨'),
    ('Build your Dream Cast', 'Use your own photos and consenting friends as recurring people in your dream worlds.', '🎭'),
    ('Share on your terms', 'Keep a dream private, share with friends, or publish it to the public Dream Feed.', '🌙'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DreamGradient(
      child: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              onPageChanged: (i) => setState(() => page = i),
              itemCount: pages.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(pages[i].$3, style: const TextStyle(fontSize: 92)),
                  const SizedBox(height: 34),
                  Text(pages[i].$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  Text(pages[i].$2, textAlign: TextAlign.center, style: const TextStyle(color: DreamColors.muted, height: 1.5, fontSize: 16)),
                ]),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pages.length, (i) => Container(
            margin: const EdgeInsets.all(4), width: i == page ? 24 : 8, height: 8,
            decoration: BoxDecoration(color: i == page ? DreamColors.violet : Colors.white24, borderRadius: BorderRadius.circular(8)),
          ))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: page == pages.length - 1 ? widget.onFinished : () => controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text(page == pages.length - 1 ? 'Enter Dream Logs' : 'Continue'),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}
