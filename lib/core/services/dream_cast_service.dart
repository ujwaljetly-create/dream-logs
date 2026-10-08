import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CastUser {
  const CastUser({required this.uid, required this.username, required this.displayName, this.photoUrl});
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
}

class DreamCastService {
  DreamCastService()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance,
        _picker = ImagePicker();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  String get uid => _auth.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPersonas() =>
      _firestore.collection('users').doc(uid).collection('personas').orderBy('createdAt').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchIncomingInvites() =>
      _firestore.collection('castInvites').where('recipientUid', isEqualTo: uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSentInvites() =>
      _firestore.collection('castInvites').where('senderUid', isEqualTo: uid).snapshots();

  Future<XFile?> pickPhoto(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 88, maxWidth: 1800);

  Future<CastUser?> findUser(String username) async {
    final normalized = username.trim().toLowerCase().replaceFirst('@', '');
    if (normalized.length < 3) return null;
    final usernameDoc = await _firestore.collection('usernames').doc(normalized).get();
    if (!usernameDoc.exists) return null;
    final foundUid = usernameDoc.data()!['uid'] as String;
    if (foundUid == uid) return null;
    final userDoc = await _firestore.collection('users').doc(foundUid).get();
    if (!userDoc.exists) return null;
    final data = userDoc.data()!;
    return CastUser(
      uid: foundUid,
      username: data['username'] as String? ?? normalized,
      displayName: data['displayName'] as String? ?? normalized,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Future<CastUser?> getUserByUid(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    final username = d['username'] as String? ?? '';
    return CastUser(
      uid: userId,
      username: username,
      displayName: (d['displayName'] as String? ?? '').trim().isNotEmpty
          ? d['displayName'] as String : username,
      photoUrl: d['photoUrl'] as String?,
    );
  }

  Future<void> createPersona({required String name, required XFile photo}) async {
    final ref = _firestore.collection('users').doc(uid).collection('personas').doc();
    final ext = photo.name.contains('.') ? photo.name.split('.').last : 'jpg';
    final path = 'users/' + uid + '/personas/' + ref.id + '/' +
        DateTime.now().millisecondsSinceEpoch.toString() + '.' + ext;
    final storageRef = _storage.ref(path);
    await storageRef.putFile(File(photo.path));
    final url = await storageRef.getDownloadURL();
    await ref.set({
      'ownerUid': uid, 'name': name.trim(), 'photoUrls': [url], 'isSelf': false,
      'canBeUsedByFriends': false, 'linkedUserUid': null,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPhoto(String personaId, XFile photo) async {
    final ext = photo.name.contains('.') ? photo.name.split('.').last : 'jpg';
    final path = 'users/' + uid + '/personas/' + personaId + '/' +
        DateTime.now().millisecondsSinceEpoch.toString() + '.' + ext;
    final storageRef = _storage.ref(path);
    await storageRef.putFile(File(photo.path));
    final url = await storageRef.getDownloadURL();
    await _firestore.collection('users').doc(uid).collection('personas').doc(personaId).update({
      'photoUrls': FieldValue.arrayUnion([url]), 'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendInvite(CastUser recipient) async {
    final senderDoc = await _firestore.collection('users').doc(uid).get();
    final sender = senderDoc.data() ?? {};
    final inviteRef = _firestore.collection('castInvites').doc(uid + '_' + recipient.uid);
    final existing = await inviteRef.get();
    if (existing.exists && (existing.data()?['status'] == 'pending' ||
        existing.data()?['status'] == 'accepted')) {
      throw StateError('This invitation is already pending or accepted.');
    }
    await inviteRef.set({
      'senderUid': uid,
      'senderUsername': sender['username'] ?? '',
      'senderDisplayName': sender['displayName'] ?? '',
      'senderPhotoUrl': sender['photoUrl'],
      'recipientUid': recipient.uid,
      'recipientUsername': recipient.username,
      'recipientDisplayName': recipient.displayName,
      'recipientPhotoUrl': recipient.photoUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToInvite(DocumentReference<Map<String, dynamic>> ref, bool accept) async {
    if (!accept) {
      await ref.update({'status': 'declined', 'respondedAt': FieldValue.serverTimestamp()});
      return;
    }
    await ref.update({
      'status': 'accepted',
      'likenessPermission': false,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setLikenessPermission(DocumentReference<Map<String, dynamic>> ref, bool allowed) =>
      ref.update({'likenessPermission': allowed, 'permissionUpdatedAt': FieldValue.serverTimestamp()});
}
