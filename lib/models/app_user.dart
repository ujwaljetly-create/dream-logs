class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String bio;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.bio = '',
  });

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'username': username,
        'photoUrl': photoUrl,
        'bio': bio,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        username: map['username'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        bio: map['bio'] as String? ?? '',
      );
}
