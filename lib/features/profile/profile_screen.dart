import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../dreams/dream_library_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dream_gradient.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final service = ProfileService();

  Future<void> _edit(Map<String, dynamic> data) async {
    final name = TextEditingController(text: data['displayName'] as String? ?? '');
    final bio = TextEditingController(text: data['bio'] as String? ?? '');
    final save = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Edit profile'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Display name')),
        const SizedBox(height: 12),
        TextField(controller: bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
      ],
    ));
    if (save == true) await service.updateProfile(displayName: name.text, bio: bio.text);
  }

  @override
  Widget build(BuildContext context) => DreamGradient(child: SafeArea(
    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.watchProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final photo = data['photoUrl'] as String?;
        final username = data['username'] as String? ?? '';
        return ListView(padding: const EdgeInsets.all(20), children: [
          const SizedBox(height: 18),
          Center(child: Stack(children: [
            CircleAvatar(radius: 48, backgroundColor: DreamColors.surface2,
              backgroundImage: photo == null ? null : NetworkImage(photo),
              child: photo == null ? const Icon(Icons.person_outline, size: 42) : null),
            Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 17, backgroundColor: DreamColors.violet,
              child: IconButton(padding: EdgeInsets.zero, iconSize: 18, onPressed: service.uploadProfilePhoto, icon: const Icon(Icons.camera_alt_outlined)))),
          ])),
          const SizedBox(height: 12),
          Center(child: Text(data['displayName'] as String? ?? 'Your Dream Log', style: Theme.of(context).textTheme.headlineMedium)),
          Center(child: Text('@' + username, style: const TextStyle(color: DreamColors.muted))),
          const SizedBox(height: 12),
          Center(child: OutlinedButton.icon(onPressed: () => _edit(data), icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile'))),
          const SizedBox(height: 18),
          Text(data['bio'] as String? ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const DreamLibraryScreen())),
            icon: const Icon(Icons.auto_stories_outlined), label: const Text('My Dream Library')),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: Text('My Dream Persona', style: Theme.of(context).textTheme.titleLarge)),
            FilledButton.icon(onPressed: service.addDreamReferencePhoto, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Add photo')),
          ]),
          const SizedBox(height: 8),
          const Text('Choose the photos Dream Logs may use to recreate you. You can turn access off for any photo at any time.',
            style: TextStyle(color: DreamColors.muted, height: 1.4)),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.watchDreamPhotos(),
            builder: (context, photos) {
              if (!photos.hasData) return const Center(child: CircularProgressIndicator());
              if (photos.data!.docs.isEmpty) return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No Dream Persona photos yet.', style: TextStyle(color: DreamColors.muted)));
              return Column(children: photos.data!.docs.map((doc) {
                final d = doc.data();
                final allowed = d['availableForDreams'] as bool? ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(d['url'] as String, width: 64, height: 64, fit: BoxFit.cover)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Available for dream creation')),
                    Switch(value: allowed, onChanged: (v) => service.setDreamPhotoAvailable(doc.id, v)),
                  ]),
                );
              }).toList());
            },
          ),
        ]);
      },
    ),
  ));
}
