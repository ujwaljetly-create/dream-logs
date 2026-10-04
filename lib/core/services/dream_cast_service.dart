import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<XFile?> pickPhoto(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 88, maxWidth: 1800);

  Future<void> createPersona({required String name, required XFile photo}) async {
    final ref = _firestore.collection('users').doc(uid).collection('personas').doc();
    final ext = photo.name.contains('.') ? photo.name.split('.').last : 'jpg';
    final path = 'users/' + uid + '/personas/' + ref.id + '/' +
        DateTime.now().millisecondsSinceEpoch.toString() + '.' + ext;
    final storageRef = _storage.ref(path);
    await storageRef.putFile(File(photo.path));
    final url = await storageRef.getDownloadURL();
    await ref.set({
      'ownerUid': uid,
      'name': name.trim(),
      'photoUrls': [url],
      'isSelf': false,
      'canBeUsedByFriends': false,
      'linkedUserUid': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
      'photoUrls': FieldValue.arrayUnion([url]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendInvite(String username) async {
    final normalized = username.trim().toLowerCase().replaceFirst('@', '');
    if (normalized.isEmpty) throw Exception('Enter a username.');
    final usernameDoc = await _firestore.collection('usernames').doc(normalized).get();
    if (!usernameDoc.exists) throw Exception('No Dream Logs user found with @' + normalized + '.');
    final recipientUid = usernameDoc.data()!['uid'] as String;
    if (recipientUid == uid) throw Exception('You cannot invite yourself.');
    await _firestore.collection('castInvites').doc(uid + '_' + recipientUid).set({
      'senderUid': uid,
      'recipientUid': recipientUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
