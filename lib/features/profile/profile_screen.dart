import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DreamGradient(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 18),
          const Center(child: CircleAvatar(radius: 48, backgroundColor: DreamColors.surface2, child: Text('🌙', style: TextStyle(fontSize: 42)))),
          const SizedBox(height: 12),
          Center(child: Text('Your Dream Log', style: Theme.of(context).textTheme.headlineMedium)),
          const Center(child: Text('@dreamer', style: TextStyle(color: DreamColors.muted))),
          const SizedBox(height: 20),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Stat(value: '12', label: 'Dreams'),
            _Stat(value: '248', label: 'Followers'),
            _Stat(value: '91', label: 'Following'),
          ]),
          const SizedBox(height: 22),
          const Text('Collecting the places I visit after I close my eyes. ✨', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text('Dreams')),
              ButtonSegment(value: 1, label: Text('Tagged')),
              ButtonSegment(value: 2, label: Text('Private')),
            ],
            selected: {0},
          ),
          const SizedBox(height: 22),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            children: ['🏰','🪐','🌊','🌃','🦋','🌙'].map((e) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Text(e, style: const TextStyle(fontSize: 34)),
            )).toList(),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Arial')),
    Text(label, style: const TextStyle(color: DreamColors.muted, fontSize: 12)),
  ]);
}
