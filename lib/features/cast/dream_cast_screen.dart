import 'dart:async';

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
      context: context, isScrollControlled: true, backgroundColor: DreamColors.surface,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Add to Dream Cast', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () async {
              photo = await _service.pickPhoto(ImageSource.gallery); setSheetState(() {});
            }, icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: () async {
              photo = await _service.pickPhoto(ImageSource.camera); setSheetState(() {});
            }, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera'))),
          ]),
          if (photo != null) Padding(padding: const EdgeInsets.only(top: 10),
            child: Text('Selected: ' + photo!.name, style: const TextStyle(color: DreamColors.blue))),
          const SizedBox(height: 16),
          FilledButton(onPressed: () async {
            if (name.text.trim().isEmpty || photo == null) return;
            Navigator.pop(sheetContext);
            try { await _service.createPersona(name: name.text, photo: photo!); }
            catch (e) { if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Could not add person: ' + e.toString()))); }
          }, child: const Text('Add person')),
        ]),
      )),
    );
  }

  Future<void> _invite() async {
    final selected = await showDialog<CastUser>(
      context: context,
      builder: (_) => _InviteDialog(service: _service),
    );
    if (selected == null) return;
    try {
      await _service.sendInvite(selected);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite sent to @' + selected.username + '.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send invite: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => DreamGradient(child: SafeArea(child: ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(children: [
        Expanded(child: Text('Dream Cast', style: Theme.of(context).textTheme.headlineMedium)),
        IconButton(onPressed: _invite, tooltip: 'Invite person', icon: const Icon(Icons.person_add_alt_1)),
        IconButton(onPressed: _addPerson, tooltip: 'Add person', icon: const Icon(Icons.add_a_photo_outlined)),
      ]),
      const SizedBox(height: 8),
      const Text('Build reusable characters from your photos, or invite friends. Friends explicitly control whether their likeness can be used in generated dreams.',
        style: TextStyle(color: DreamColors.muted, height: 1.45)),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: _addPerson, icon: const Icon(Icons.add), label: const Text('Add person'))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(onPressed: _invite, icon: const Icon(Icons.send_outlined), label: const Text('Send invite'))),
      ]),
      const SizedBox(height: 24),
      const _SectionTitle('Friends'),
      const SizedBox(height: 10),
      _Friends(service: _service),
      const SizedBox(height: 24),
      const _SectionTitle('Pending invitations'),
      const SizedBox(height: 10),
      _Invitations(service: _service),
      const SizedBox(height: 24),
      const _SectionTitle('Your personas'),
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchPersonas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Could not load Dream Cast: ' + snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const _EmptyCast();
          return Column(children: snapshot.data!.docs.map((doc) {
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
    ],
  )));

}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.service});
  final DreamCastService service;
  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final controller = TextEditingController();
  Timer? debounce;
  CastUser? result;
  bool searching = false;

  Future<void> search(String value) async {
    debounce?.cancel();
    setState(() { result = null; searching = value.trim().replaceFirst('@', '').length >= 3; });
    if (!searching) return;
    debounce = Timer(const Duration(milliseconds: 250), () async {
      final found = await widget.service.findUser(value);
      if (mounted && controller.text == value) setState(() { result = found; searching = false; });
    });
  }

  @override
  void dispose() { debounce?.cancel(); controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Invite to Dream Cast'),
    content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: controller, autofocus: true, onChanged: search,
        decoration: const InputDecoration(hintText: '@username', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12),
      if (searching) const LinearProgressIndicator(),
      if (!searching && result != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: DreamColors.surface2,
            backgroundImage: result!.photoUrl == null ? null : NetworkImage(result!.photoUrl!),
            child: result!.photoUrl == null ? const Icon(Icons.person_outline) : null),
          title: Text(result!.displayName),
          subtitle: Text('@' + result!.username),
          trailing: FilledButton(onPressed: () => Navigator.pop(context, result), child: const Text('Invite')),
        ),
      if (!searching && result == null && controller.text.trim().replaceFirst('@', '').length >= 3)
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('No matching user yet.', style: TextStyle(color: DreamColors.muted))),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
  );
}

class _Invitations extends StatelessWidget {
  const _Invitations({required this.service});
  final DreamCastService service;

  @override
  Widget build(BuildContext context) => Column(children: [
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchIncomingInvites(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs.where((d) => d.data()['status'] == 'pending').toList() ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(children: docs.map((doc) {
          final d = doc.data();
          return _InviteCard(
            name: _inviteName(d, 'sender'),
            username: d['senderUsername'] as String? ?? '',
            photoUrl: d['senderPhotoUrl'] as String?,
            label: 'wants to join your Dream Cast',
            actions: [
              TextButton(onPressed: () => service.respondToInvite(doc.reference, false), child: const Text('Decline')),
              FilledButton(onPressed: () => service.respondToInvite(doc.reference, true), child: const Text('Accept')),
            ]);
        }).toList());
      },
    ),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchSentInvites(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs.where((d) => d.data()['status'] == 'pending').toList() ?? [];
        if (docs.isEmpty) return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('No invitations yet.', style: TextStyle(color: DreamColors.muted)));
        return Column(children: docs.map((doc) {
          final d = doc.data();
          final status = d['status'] as String? ?? 'pending';
          return _InviteCard(
            name: _inviteName(d, 'recipient'),
            username: d['recipientUsername'] as String? ?? '',
            photoUrl: d['recipientPhotoUrl'] as String?,
            label: status == 'pending' ? 'Invite pending' : status == 'accepted' ? 'Invite accepted' : 'Invite declined',
            actions: const []);
        }).toList());
      },
    ),
  ]);
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.name, required this.username, required this.photoUrl, required this.label, required this.actions});
  final String name, username, label;
  final String? photoUrl;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      CircleAvatar(backgroundColor: DreamColors.surface2,
        backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
        child: photoUrl == null ? const Icon(Icons.person_outline) : null),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('@' + username + ' · ' + label, style: const TextStyle(color: DreamColors.muted, fontSize: 12)),
      ])),
      ...actions,
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
}

class _EmptyCast extends StatelessWidget {
  const _EmptyCast();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(22)),
    child: const Column(children: [
      Icon(Icons.groups_2_outlined, size: 42, color: DreamColors.violet), SizedBox(height: 12),
      Text('Your Dream Cast is empty', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 6),
      Text('Add yourself or another person from photos, or send a friend an invite.',
        textAlign: TextAlign.center, style: TextStyle(color: DreamColors.muted)),
    ]),
  );
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({required this.name, required this.photoUrl, required this.photoCount, required this.onAddPhoto});
  final String name; final String? photoUrl; final int photoCount; final VoidCallback onAddPhoto;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DreamColors.surface, borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      CircleAvatar(radius: 28, backgroundColor: DreamColors.surface2,
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

String _inviteName(Map<String, dynamic> data, String side) {
  final display = (data['${side}DisplayName'] as String? ?? '').trim();
  final username = (data['${side}Username'] as String? ?? '').trim();
  return display.isNotEmpty ? display : (username.isNotEmpty ? username : 'Dream Logs user');
}

class _Friends extends StatelessWidget {
  const _Friends({required this.service});
  final DreamCastService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: service.watchSentInvites(),
    builder: (context, sent) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchIncomingInvites(),
      builder: (context, incoming) {
        if (sent.hasError || incoming.hasError) return const Text('Could not load friends.');
        if (!sent.hasData || !incoming.hasData) return const LinearProgressIndicator();
        final byUid = <String, Map<String, dynamic>>{};
        for (final doc in [...sent.data!.docs, ...incoming.data!.docs]) {
          final d = doc.data();
          if (d['status'] != 'accepted') continue;
          final mine = d['senderUid'] == service.uid;
          final friendUid = (mine ? d['recipientUid'] : d['senderUid']) as String?;
          if (friendUid != null) byUid[friendUid] = d;
        }
        if (byUid.isEmpty) return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No friends yet. Accepted invitations will appear here.',
            style: TextStyle(color: DreamColors.muted)));
        return Column(children: byUid.entries.map((entry) {
          final d = entry.value;
          final side = d['senderUid'] == service.uid ? 'recipient' : 'sender';
          return FutureBuilder<CastUser?>(
            future: service.getUserByUid(entry.key),
            builder: (context, user) => _InviteCard(
              name: user.data?.displayName ?? _inviteName(d, side),
              username: user.data?.username ?? (d['${side}Username'] as String? ?? ''),
              photoUrl: user.data?.photoUrl ?? d['${side}PhotoUrl'] as String?,
              label: 'Friend · available in Dream Cast',
              actions: const [],
            ),
          );
        }).toList());
      },
    ),
  );
}
