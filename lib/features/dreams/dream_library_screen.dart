import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DreamLibraryScreen extends StatelessWidget {
  const DreamLibraryScreen({super.key, this.initialDreamId});
  final String? initialDreamId;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _export(BuildContext context, Map<String, dynamic> data) async {
    try {
      final scenes = data['scenes'] as List<dynamic>? ?? [];
      if (scenes.isEmpty) throw StateError('No generated image yet');
      final path = (scenes.first as Map)['storagePath'] as String;
      final bytes = await FirebaseStorage.instance.ref(path).getData(15 * 1024 * 1024);
      if (bytes == null) throw StateError('Could not download image');
      await SharePlus.instance.share(ShareParams(
        text: data['description'] as String? ?? 'My Dream',
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'dream.png')],
        fileNameOverrides: ['dream.png'],
      ));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not export: $e')));
    }
  }

  Future<void> _regenerate(BuildContext context, Map<String, dynamic> data) async {
    final controller = TextEditingController(text: data['description'] as String? ?? '');
    var style = data['style'] as String? ?? 'Cinematic';
    final submit = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => AlertDialog(
        title: const Text('Regenerate dream'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: controller, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'Revise dream details')),
          const SizedBox(height: 12),
          DropdownButton<String>(value: style, isExpanded: true,
            items: ['Cinematic', 'Fantasy', 'Realistic', 'Animated'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => update(() => style = v!)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate new image')),
        ],
      )));
    final prompt = controller.text.trim();
    controller.dispose();
    if (submit != true || prompt.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('dreams').add({
        'ownerUid': uid, 'description': prompt, 'type': 'story',
        'style': style, 'castIds': List<String>.from(data['castIds'] ?? const []),
        'photoIds': List<String>.from(data['photoIds'] ?? const []),
        'status': 'queued', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New version queued. It will appear in My Dreams.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not regenerate: $e')));
    }
  }

  Future<void> _edit(BuildContext context, DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data) async {
    final title = TextEditingController(text: data['title'] as String? ?? '');
    final description = TextEditingController(text: data['description'] as String? ?? '');
    final save = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit dream'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: 'Title')),
        TextField(controller: description, maxLines: 4, maxLength: 10000,
            decoration: const InputDecoration(labelText: 'Description')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (save == true) {
      await ref.update({'title': title.text.trim(), 'description': description.text.trim()});
    }
    title.dispose();
    description.dispose();
  }

  Future<void> _sharing(BuildContext context, DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data) async {
    final friends = <String, String>{};
    final db = FirebaseFirestore.instance;
    final sent = await db.collection('castInvites').where('senderUid', isEqualTo: uid).get();
    final incoming = await db.collection('castInvites').where('recipientUid', isEqualTo: uid).get();
    for (final invite in [...sent.docs, ...incoming.docs]) {
      final d = invite.data();
      if (d['status'] != 'accepted') continue;
      final mine = d['senderUid'] == uid;
      final other = (mine ? d['recipientUid'] : d['senderUid']) as String?;
      final name = (mine ? d['recipientDisplayName'] : d['senderDisplayName']) as String?;
      if (other != null) friends[other] = (name?.trim().isNotEmpty ?? false) ? name! : other;
    }
    var visibility = data['visibility'] as String? ?? 'private';
    final shared = <String>{...List<String>.from(data['sharedWith'] ?? const [])};
    final save = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => AlertDialog(
        title: const Text('Share dream'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          RadioListTile<String>(title: const Text('Private'), value: 'private',
              groupValue: visibility, onChanged: (v) => update(() => visibility = v!)),
          RadioListTile<String>(title: const Text('Selected friends'), value: 'friends',
              groupValue: visibility, onChanged: (v) => update(() => visibility = v!)),
          RadioListTile<String>(title: const Text('Public'), value: 'public',
              groupValue: visibility, onChanged: (v) => update(() => visibility = v!)),
          if (visibility == 'friends') ...[
            const Text('Choose who can see this dream:'),
            ...friends.entries.map((e) => CheckboxListTile(
              title: Text(e.value), value: shared.contains(e.key),
              onChanged: (v) => update(() => v == true ? shared.add(e.key) : shared.remove(e.key)),
            )),
            if (friends.isEmpty) const Text('No accepted friends yet.'),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    ));
    if (save == true) await ref.update({
      'visibility': visibility,
      'sharedWith': visibility == 'friends' ? shared.toList() : <String>[],
    });
  }

  Future<void> _delete(BuildContext context, DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete dream?'),
      content: const Text('This removes the dream from your library. Stored image cleanup may take longer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true) return;
    // The Firestore document is deleted first; orphaned blobs can be cleaned by a trusted backend.
    await ref.delete();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dream deleted from your library.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Dream Library')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('dreams')
          .where('ownerUid', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load dreams: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
        if (docs.isEmpty) return const Center(child: Text('Your generated dreams will appear here.'));
        if (initialDreamId != null) {
          docs.sort((a, b) => a.id == initialDreamId ? -1 : b.id == initialDreamId ? 1 : 0);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final d = doc.data();
            final scenes = d['scenes'] as List<dynamic>? ?? const [];
            final title = (d['title'] as String? ?? '').trim();
            return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.isNotEmpty ? title : (d['description'] as String? ?? 'Untitled dream'),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('${d['status'] ?? 'queued'} · ${d['visibility'] ?? 'private'}'),
                const SizedBox(height: 10),
                ...scenes.map((scene) {
                  final path = (scene as Map)['storagePath'] as String?;
                  if (path == null) return const SizedBox.shrink();
                  return FutureBuilder<String>(
                    future: FirebaseStorage.instance.ref(path).getDownloadURL(),
                    builder: (context, image) => image.hasError ? Text('Image unavailable: ${image.error}') : image.hasData
                        ? Padding(padding: const EdgeInsets.only(bottom: 8),
                            child: Image.network(image.data!, height: 220, width: double.infinity, fit: BoxFit.cover))
                        : const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
                  );
                }),
                Wrap(spacing: 8, children: [
                  TextButton.icon(onPressed: () => _export(context, d), icon: const Icon(Icons.save_alt), label: const Text('Save / Send')),
                  TextButton.icon(onPressed: () => _regenerate(context, d), icon: const Icon(Icons.refresh), label: const Text('Regenerate')),
                  TextButton.icon(onPressed: () => _edit(context, doc.reference, d),
                      icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                  TextButton.icon(onPressed: () => _sharing(context, doc.reference, d),
                      icon: const Icon(Icons.share_outlined), label: const Text('Share')),
                  TextButton.icon(onPressed: () => _delete(context, doc.reference, d),
                      icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
                ]),
              ],
            )));
          },
        );
      },
    ),
  );
}
