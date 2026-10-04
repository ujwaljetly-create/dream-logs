import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class CreateDreamScreen extends StatefulWidget {
  const CreateDreamScreen({super.key});
  @override
  State<CreateDreamScreen> createState() => _CreateDreamScreenState();
}

class _CreateDreamScreenState extends State<CreateDreamScreen> {
  bool movie = false;
  String style = 'Cinematic';

  @override
  Widget build(BuildContext context) {
    return DreamGradient(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Tell Your Dream', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Describe everything you remember. People, places, emotions, sounds — even the strange parts.', style: TextStyle(color: DreamColors.muted, height: 1.45)),
          const SizedBox(height: 20),
          const TextField(
            minLines: 6,
            maxLines: 10,
            decoration: InputDecoration(hintText: 'Last night I dreamed about...'),
          ),
          const SizedBox(height: 22),
          const Text('Who was in your dream?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
          const SizedBox(height: 12),
          const Row(children: [
            _CastChoice(label: 'Me', emoji: '🙂'),
            _CastChoice(label: 'Sarah', emoji: '👩'),
            _CastChoice(label: 'Alex', emoji: '🧔'),
            _CastChoice(label: 'Add', emoji: '＋'),
          ]),
          const SizedBox(height: 24),
          const Text('Create as', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.photo_library_outlined), label: Text('Dream Story')),
              ButtonSegment(value: true, icon: Icon(Icons.movie_creation_outlined), label: Text('Dream Movie')),
            ],
            selected: {movie},
            onSelectionChanged: (s) => setState(() => movie = s.first),
          ),
          const SizedBox(height: 24),
          const Text('Visual style', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: ['Cinematic','Fantasy','Realistic','Animated'].map((s) => ChoiceChip(label: Text(s), selected: style == s, onSelected: (_) => setState(() => style = s))).toList()),
          const SizedBox(height: 30),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: DreamColors.violet),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI generation will be connected in the next milestone.'))),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Recreate My Dream'),
          ),
        ]),
      ),
    );
  }
}

class _CastChoice extends StatelessWidget {
  final String label;
  final String emoji;
  const _CastChoice({required this.label, required this.emoji});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      CircleAvatar(radius: 27, backgroundColor: DreamColors.surface2, child: Text(emoji, style: const TextStyle(fontSize: 23))),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'Arial')),
    ]),
  );
}
