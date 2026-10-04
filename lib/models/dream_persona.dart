class DreamPersona {
  final String id;
  final String ownerUid;
  final String name;
  final List<String> photoUrls;
  final bool isSelf;
  final bool canBeUsedByFriends;
  final String? linkedUserUid;

  const DreamPersona({
    required this.id,
    required this.ownerUid,
    required this.name,
    this.photoUrls = const [],
    this.isSelf = false,
    this.canBeUsedByFriends = false,
    this.linkedUserUid,
  });

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'name': name,
        'photoUrls': photoUrls,
        'isSelf': isSelf,
        'canBeUsedByFriends': canBeUsedByFriends,
        'linkedUserUid': linkedUserUid,
      };
}
