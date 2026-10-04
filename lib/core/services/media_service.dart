abstract class MediaService {
  Future<String?> pickFromGallery();
  Future<String?> takePhoto();
  Future<String> uploadPersonaPhoto({
    required String userId,
    required String personaId,
    required String localPath,
  });
}

/// Firebase Storage + image_picker implementation will replace this adapter
/// once the Firebase project is configured.
class MockMediaService implements MediaService {
  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<String?> takePhoto() async => null;

  @override
  Future<String> uploadPersonaPhoto({
    required String userId,
    required String personaId,
    required String localPath,
  }) async => localPath;
}
