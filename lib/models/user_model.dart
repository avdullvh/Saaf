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

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.postCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:        j['id']         as int,
    fullName:  j['full_name']  as String,
    email:     j['email']      as String,
    bio:       j['bio']        as String?,
    avatarUrl: j['avatar_url'] as String?,
    postCount: (j['post_count'] as int?) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id':         id,
    'full_name':  fullName,
    'email':      email,
    'bio':        bio,
    'avatar_url': avatarUrl,
    'post_count': postCount,
  };

  UserModel copyWith({
    String? fullName,
    String? bio,
    String? avatarUrl,
    int?    postCount,
  }) => UserModel(
    id:        id,
    fullName:  fullName   ?? this.fullName,
    email:     email,
    bio:       bio        ?? this.bio,
    avatarUrl: avatarUrl  ?? this.avatarUrl,
    postCount: postCount  ?? this.postCount,
  );
}