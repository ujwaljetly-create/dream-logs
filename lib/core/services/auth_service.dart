import '../../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });
  Future<void> signOut();
}

class MockAuthService implements AuthService {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_user);

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    _user = AppUser(id: 'mock-user', email: email, displayName: 'Dreamer', username: 'dreamer');
    return _user!;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    _user = AppUser(id: 'mock-user', email: email, displayName: displayName, username: username);
    return _user!;
  }

  @override
  Future<void> signOut() async => _user = null;
}
