// ─────────────────────────────────────────────
// lib/models/post_model.dart
// A community feed post, optionally carrying a classification result
// ─────────────────────────────────────────────
import 'classification_result_model.dart';

class CommentModel {
  final int    id;
  final String authorName;
  final String body;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
    id:         j['id']          as int,
    authorName: j['author_name'] as String,
    body:       j['body']        as String,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );

  // ── Mock ──
  static List<CommentModel> mockList() => [
    CommentModel(
      id: 1, authorName: 'Ahmed Ali',
      body: 'Great result! I have the same type.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CommentModel(
      id: 2, authorName: 'Sara Hassan',
      body: 'How do you take care of Khalas trees?',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}

class PostModel {
  final int    id;
  final int?   authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String? caption;
  final String? imageUrl;
  final ClassificationResult? classification;
  final int  likesCount;
  final bool likedByMe;
  final int  commentsCount;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.caption,
    this.imageUrl,
    this.classification,
    required this.likesCount,
    required this.likedByMe,
    required this.commentsCount,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> j) => PostModel(
    id:               j['id']               as int,
    authorId:         j['author_id']        as int?,
    authorName:       j['author_name']      as String,
    authorAvatarUrl:  j['author_avatar_url'] as String?,
    caption:          j['caption']          as String?,
    imageUrl:         j['image_url']        as String?,
    classification: j['classification'] != null
        ? ClassificationResult.fromJson(
            j['classification'] as Map<String, dynamic>)
        : null,
    likesCount:    j['likes_count']    as int,
    likedByMe:     j['liked_by_me']    as bool,
    commentsCount: j['comments_count'] as int,
    createdAt:     DateTime.parse(j['created_at'] as String),
  );

  PostModel copyWith({int? likesCount, bool? likedByMe}) => PostModel(
    id:              id,
    authorId:        authorId,
    authorName:      authorName,
    authorAvatarUrl: authorAvatarUrl,
    caption:         caption,
    imageUrl:        imageUrl,
    classification:  classification,
    likesCount:      likesCount    ?? this.likesCount,
    likedByMe:       likedByMe     ?? this.likedByMe,
    commentsCount:   commentsCount,
    createdAt:       createdAt,
  );

  // ── Mock list ──
  static List<PostModel> mockList() => [
    PostModel(
      id: 1, authorId: 10, authorName: 'Mohammed Al-Qahtani',
      caption: 'Just classified this frond from my farm!',
      imageUrl: null,
      classification: ClassificationResult.mock(),
      likesCount: 12, likedByMe: false, commentsCount: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PostModel(
      id: 2, authorId: 11, authorName: 'Fatima Al-Dosari',
      caption: 'Interesting result on this one.',
      imageUrl: null,
      classification: const ClassificationResult(
        predictedType: 'Razeez', confidenceScore: 0.9102,
      ),
      likesCount: 5, likedByMe: true, commentsCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}