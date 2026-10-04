import 'package:flutter/material.dart';
import '../../widgets/dream_gradient.dart';
import '../../widgets/dream_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DreamGradient(
      child: SafeArea(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Text('Dream Logs', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 102,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: const [
                  _DreamBubble(label: 'Your Dream', emoji: '✨'),
                  _DreamBubble(label: 'Sarah', emoji: '🌙'),
                  _DreamBubble(label: 'Alex', emoji: '🪐'),
                  _DreamBubble(label: 'Priya', emoji: '🦋'),
                  _DreamBubble(label: 'James', emoji: '🌌'),
                ],
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 4, 18, 30),
            sliver: SliverList(delegate: SliverChildListDelegate.fixed([
              DreamCard(author: 'Emma Carter', title: 'A Magical Journey', description: 'We were flying through floating islands above the clouds. Everything felt impossibly peaceful.', emoji: '🏰 ☁️ ✨', stats: '1.2K'),
              DreamCard(author: 'Liam Park', title: 'Walking on Mars', description: 'The sky was violet, the stars were brighter than ever, and my dog somehow knew the way home.', emoji: '🪐 🚀 🌙', stats: '23.4K'),
            ])),
          ),
        ]),
      ),
    );
  }
}

class _DreamBubble extends StatelessWidget {
  final String label;
  final String emoji;
  const _DreamBubble({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFB66CFF), Color(0xFF61D4FF)]),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 7),
        Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontFamily: 'Arial')),
      ]),
    );
  }
}
