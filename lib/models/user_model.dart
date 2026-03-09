// ─────────────────────────────────────────────
// lib/models/user_model.dart
// ─────────────────────────────────────────────
class UserModel {
  final int    id;
  final String fullName;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final int     postCount;
  final int     followersCount;
  final int     followingCount;
  final bool    isFollowing;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.postCount      = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing    = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:             j['id']              as int,
    fullName:       j['full_name']       as String,
    email:          j['email']           as String,
    bio:            j['bio']             as String?,
    avatarUrl:      j['avatar_url']      as String?,
    postCount:      (j['post_count']      as int?) ?? 0,
    followersCount: (j['followers_count'] as int?) ?? 0,
    followingCount: (j['following_count'] as int?) ?? 0,
    isFollowing:    (j['is_following']    as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id':              id,
    'full_name':       fullName,
    'email':           email,
    'bio':             bio,
    'avatar_url':      avatarUrl,
    'post_count':      postCount,
    'followers_count': followersCount,
    'following_count': followingCount,
    'is_following':    isFollowing,
  };

  UserModel copyWith({
    String? fullName,
    String? bio,
    String? avatarUrl,
    int?    postCount,
    int?    followersCount,
    int?    followingCount,
    bool?   isFollowing,
  }) => UserModel(
    id:             id,
    fullName:       fullName       ?? this.fullName,
    email:          email,
    bio:            bio            ?? this.bio,
    avatarUrl:      avatarUrl      ?? this.avatarUrl,
    postCount:      postCount      ?? this.postCount,
    followersCount: followersCount ?? this.followersCount,
    followingCount: followingCount ?? this.followingCount,
    isFollowing:    isFollowing    ?? this.isFollowing,
  );
}