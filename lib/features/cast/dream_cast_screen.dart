import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class DreamCastScreen extends StatelessWidget {
  const DreamCastScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DreamGradient(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            Text('Dream Cast', style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.add_a_photo_outlined)),
          ]),
          const SizedBox(height: 8),
          const Text('Create reusable personas from photos. Friends control whether their persona can appear in your generated dreams.', style: TextStyle(color: DreamColors.muted, height: 1.45)),
          const SizedBox(height: 22),
          const _Persona(name: 'Me', photos: '8 photos', emoji: '🙂', enabled: true),
          const _Persona(name: 'Sarah', photos: '5 photos', emoji: '👩', enabled: true),
          const _Persona(name: 'Alex', photos: '4 photos', emoji: '🧔', enabled: false),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add person or photo')),
        ]),
      ),
    );
  }
}

class _Persona extends StatelessWidget {
  final String name;
  final String photos;
  final String emoji;
  final bool enabled;
  const _Persona({required this.name, required this.photos, required this.emoji, required this.enabled});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      CircleAvatar(radius: 28, backgroundColor: DreamColors.surface2, child: Text(emoji, style: const TextStyle(fontSize: 26))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
        Text(photos, style: const TextStyle(color: DreamColors.muted, fontSize: 12)),
      ])),
      Icon(enabled ? Icons.verified_user : Icons.lock_outline, color: enabled ? DreamColors.blue : DreamColors.muted),
    ]),
  );
}
