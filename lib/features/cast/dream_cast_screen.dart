import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/dream_cast_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class DreamCastScreen extends StatefulWidget {
  const DreamCastScreen({super.key});
  @override
  State<DreamCastScreen> createState() => _DreamCastScreenState();
}

class _DreamCastScreenState extends State<DreamCastScreen> {
  final _service = DreamCastService();

  Future<void> _addPerson() async {
    final name = TextEditingController();
    XFile? photo;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DreamColors.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Add to Dream Cast', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { photo = await _service.pickPhoto(ImageSource.gallery); setSheetState(() {}); },
                icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () async { photo = await _service.pickPhoto(ImageSource.camera); setSheetState(() {}); },
                icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera'))),
            ]),
            if (photo != null) Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Selected: ' + photo!.name, style: const TextStyle(color: DreamColors.blue))),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || photo == null) return;
                Navigator.pop(sheetContext);
                try {
                  await _service.createPersona(name: name.text, photo: photo!);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not add person: ' + e.toString())));
                }
              },
              child: const Text('Add person')),
          ]),
        ),
      ),
    );
  }

  Future<void> _invite() async {
    final username = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite to Dream Cast'),
        content: TextField(controller: username, autofocus: true, decoration: const InputDecoration(hintText: '@username')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, username.text), child: const Text('Send invite')),
        ],
      ),
    );
    if (value == null) return;
    try {
      await _service.sendInvite(value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dream Cast invite sent.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DreamGradient(
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            Expanded(child: Text('Dream Cast', style: Theme.of(context).textTheme.headlineMedium)),
            IconButton(onPressed: _invite, tooltip: 'Invite person', icon: const Icon(Icons.person_add_alt_1)),
            IconButton(onPressed: _addPerson, tooltip: 'Add person', icon: const Icon(Icons.add_a_photo_outlined)),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Build reusable characters from your photos, or invite friends to share a Dream Persona with you. Friends always control permission to use their likeness.',
            style: TextStyle(color: DreamColors.muted, height: 1.45)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: _addPerson, icon: const Icon(Icons.add), label: const Text('Add person'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: _invite, icon: const Icon(Icons.send_outlined), label: const Text('Send invite'))),
          ]),
          const SizedBox(height: 22),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.watchPersonas(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Could not load Dream Cast: ' + snapshot.error.toString(), style: const TextStyle(color: DreamColors.muted));
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const _EmptyCast();
              return Column(children: docs.map((doc) {
                final data = doc.data();
                final urls = List<String>.from(data['photoUrls'] ?? const []);
                return _PersonaCard(
                  name: data['name'] as String? ?? 'Dream Persona',
                  photoUrl: urls.isEmpty ? null : urls.first,
                  photoCount: urls.length,
                  onAddPhoto: () async {
                    final selected = await _service.pickPhoto(ImageSource.gallery);
                    if (selected != null) await _service.addPhoto(doc.id, selected);
                  },
                );
              }).toList());
            },
          ),
        ]),
      ),
    );
  }
}

class _EmptyCast extends StatelessWidget {
  const _EmptyCast();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(22)),
    child: const Column(children: [
      Icon(Icons.groups_2_outlined, size: 42, color: DreamColors.violet),
      SizedBox(height: 12),
      Text('Your Dream Cast is empty', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 6),
      Text('Add yourself or another person from photos, or send a friend an invite.',
        textAlign: TextAlign.center, style: TextStyle(color: DreamColors.muted)),
    ]),
  );
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({required this.name, required this.photoUrl, required this.photoCount, required this.onAddPhoto});
  final String name;
  final String? photoUrl;
  final int photoCount;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: DreamColors.surface2,
        backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
        child: photoUrl == null ? const Icon(Icons.person_outline) : null),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial')),
        Text(photoCount.toString() + ' reference photo' + (photoCount == 1 ? '' : 's'),
          style: const TextStyle(color: DreamColors.muted, fontSize: 12)),
      ])),
      IconButton(onPressed: onAddPhoto, tooltip: 'Add reference photo', icon: const Icon(Icons.add_a_photo_outlined)),
    ]),
  );
}
