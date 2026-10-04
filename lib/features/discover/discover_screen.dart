import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final dreams = [('Tokyo after midnight','🌃'),('Underwater city','🐋'),('Childhood home','🏡'),('Dancing in the rain','🌧️'),('Moon garden','🌙'),('Floating islands','🏰')];
    return DreamGradient(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Discover Dreams', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search dreams, people or themes')),
          const SizedBox(height: 16),
          const Wrap(spacing: 8, children: [
            Chip(label: Text('For You')),
            Chip(label: Text('Fantasy')),
            Chip(label: Text('Adventure')),
            Chip(label: Text('Love')),
          ]),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dreams.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .82),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Center(child: Text(dreams[i].$2, style: const TextStyle(fontSize: 58)))),
                Text(dreams[i].$1, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
                const SizedBox(height: 4),
                const Text('▶ 12.4K', style: TextStyle(color: DreamColors.muted, fontSize: 12)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
