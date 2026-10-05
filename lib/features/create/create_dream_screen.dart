import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final selected = <String>{};

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) => DreamGradient(child: SafeArea(child: ListView(
    padding: const EdgeInsets.all(20), children: [
      Text('Tell Your Dream', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('Describe everything you remember. People, places, emotions, sounds — even the strange parts.',
        style: TextStyle(color: DreamColors.muted, height: 1.45)),
      const SizedBox(height: 20),
      const TextField(minLines: 6, maxLines: 10, decoration: InputDecoration(hintText: 'Last night I dreamed about...')),
      const SizedBox(height: 22),
      const Text('Who was in your dream?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
      const SizedBox(height: 6),
      const Text('Only friends who accepted your invite are shown. Their approved Dream Persona photos are used at generation time.',
        style: TextStyle(color: DreamColors.muted, fontSize: 12)),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('castInvites').where(Filter.or(
          Filter('senderUid', isEqualTo: uid), Filter('recipientUid', isEqualTo: uid))).snapshots(),
        builder: (context, snapshot) {
          final accepted = snapshot.data?.docs.where((d) => d.data()['status'] == 'accepted').toList() ?? [];
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _CastChoice(label: 'Me', photoUrl: null, selected: selected.contains(uid), onTap: () => _toggle(uid)),
            ...accepted.map((doc) {
              final d = doc.data();
              final mine = d['senderUid'] == uid;
              final id = (mine ? d['recipientUid'] : d['senderUid']) as String;
              final name = (mine ? d['recipientDisplayName'] : d['senderDisplayName']) as String? ?? 'Friend';
              final photo = (mine ? d['recipientPhotoUrl'] : d['senderPhotoUrl']) as String?;
              return _CastChoice(label: name, photoUrl: photo, selected: selected.contains(id), onTap: () => _toggle(id));
            }),
          ]);
        },
      ),
      const SizedBox(height: 24),
      const Text('Create as', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
      const SizedBox(height: 10),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, icon: Icon(Icons.photo_library_outlined), label: Text('Dream Story')),
          ButtonSegment(value: true, icon: Icon(Icons.movie_creation_outlined), label: Text('Dream Movie')),
        ],
        selected: {movie}, onSelectionChanged: (s) => setState(() => movie = s.first)),
      const SizedBox(height: 24),
      const Text('Visual style', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: ['Cinematic','Fantasy','Realistic','Animated'].map((s) =>
        ChoiceChip(label: Text(s), selected: style == s, onSelected: (_) => setState(() => style = s))).toList()),
      const SizedBox(height: 30),
      FilledButton.icon(
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: DreamColors.violet),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Dream cast ready: ' + selected.length.toString() + ' selected. AI generation is next.'))),
        icon: const Icon(Icons.auto_awesome), label: const Text('Recreate My Dream')),
    ],
  )));

  void _toggle(String id) => setState(() => selected.contains(id) ? selected.remove(id) : selected.add(id));
}

class _CastChoice extends StatelessWidget {
  const _CastChoice({required this.label, required this.photoUrl, required this.selected, required this.onTap});
  final String label; final String? photoUrl; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 76, child: Column(children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: selected ? DreamColors.violet : Colors.transparent, width: 3)),
        child: CircleAvatar(radius: 28, backgroundColor: DreamColors.surface2,
          backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
          child: photoUrl == null ? const Icon(Icons.person_outline) : null)),
      const SizedBox(height: 6),
      Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontFamily: 'Arial')),
    ])),
  );
}
