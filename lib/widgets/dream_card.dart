import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DreamCard extends StatelessWidget {
  final String author;
  final String title;
  final String description;
  final String emoji;
  final String stats;

  const DreamCard({
    super.key,
    required this.author,
    required this.title,
    required this.description,
    required this.emoji,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: DreamColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(backgroundColor: DreamColors.violet.withValues(alpha: .3), child: Text(author[0])),
            const SizedBox(width: 10),
            Expanded(child: Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'))),
            const Icon(Icons.more_horiz),
          ]),
        ),
        Container(
          height: 240,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF40236F), Color(0xFF112A55), Color(0xFF19132E)],
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 78)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(description, style: const TextStyle(color: DreamColors.muted, height: 1.4)),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.favorite, size: 20, color: DreamColors.pink),
              const SizedBox(width: 6),
              Text(stats),
              const SizedBox(width: 20),
              const Icon(Icons.mode_comment_outlined, size: 20),
              const SizedBox(width: 6),
              const Text('86'),
              const Spacer(),
              const Icon(Icons.ios_share, size: 20),
            ]),
          ]),
        ),
      ]),
    );
  }
}
