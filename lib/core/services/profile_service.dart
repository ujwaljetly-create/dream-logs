import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  String get uid => _auth.currentUser!.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      _db.collection('users').doc(uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDreamPhotos() =>
      _db.collection('users').doc(uid).collection('dreamPhotos').orderBy('createdAt').snapshots();

  Future<void> updateProfile({required String displayName, required String bio}) async {
    await _db.collection('users').doc(uid).update({
      'displayName': displayName.trim(),
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auth.currentUser?.updateDisplayName(displayName.trim());
  }

  Future<void> uploadProfilePhoto({ImageSource source = ImageSource.gallery}) async {
    final photo = await _picker.pickImage(source: source, imageQuality: 88, maxWidth: 1400);
    if (photo == null) return;
    final ref = _storage.ref('users/' + uid + '/profile/avatar.jpg');
    await ref.putFile(File(photo.path));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({'photoUrl': url, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> addDreamReferencePhoto({ImageSource source = ImageSource.gallery}) async {
    final photo = await _picker.pickImage(source: source, imageQuality: 90, maxWidth: 1800);
    if (photo == null) return;
    final doc = _db.collection('users').doc(uid).collection('dreamPhotos').doc();
    final ext = photo.name.contains('.') ? photo.name.split('.').last : 'jpg';
    final ref = _storage.ref('users/' + uid + '/dreamPhotos/' + doc.id + '.' + ext);
    await ref.putFile(File(photo.path));
    final url = await ref.getDownloadURL();
    await doc.set({
      'url': url,
      'storagePath': ref.fullPath,
      'availableForDreams': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> useProfilePictureForDreams() async {
    final profile = await _db.collection('users').doc(uid).get();
    final url = profile.data()?['photoUrl'] as String?;
    if (url == null || url.isEmpty) throw StateError('Add a profile picture first.');
    final original = _storage.ref('users/$uid/profile/avatar.jpg');
    final bytes = await original.getData(10 * 1024 * 1024);
    if (bytes == null) throw StateError('Profile picture unavailable.');
    final doc = _db.collection('users').doc(uid).collection('dreamPhotos').doc();
    final dest = _storage.ref('users/$uid/dreamPhotos/${doc.id}.jpg');
    await dest.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await doc.set({
      'url': await dest.getDownloadURL(), 'storagePath': dest.fullPath,
      'availableForDreams': true, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDreamPhotoAvailable(String photoId, bool value) =>
      _db.collection('users').doc(uid).collection('dreamPhotos').doc(photoId).update({'availableForDreams': value});
}
