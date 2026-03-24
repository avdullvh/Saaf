// ─────────────────────────────────────────────
// lib/screens/feed/widgets/post_card.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/post_model.dart';
import '../../../providers/feed_provider.dart';
import '../../profile/profile_screen.dart';
import 'comment_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';

class PostCard extends StatelessWidget {
  /// The post data to display.
  final PostModel post;

  /// The index of this post in [FeedProvider]'s list, used when
  /// toggling likes so the provider knows which entry to update.
  final int index;

  const PostCard({super.key, required this.post, required this.index});

  /// Formats a [DateTime] into a short relative time string
  /// e.g. "2h ago", "1d ago", or the raw date for older posts.
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Opens the [CommentSheet] bottom sheet for this post,
  /// allowing the user to read and add comments.
  void _openComments(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(postId: post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Post header: avatar + author + timestamp ──────────────────
            GestureDetector(
              onTap: post.authorId != null
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(userId: post.authorId!),
                      ))
                  : null,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: (post.authorAvatarUrl != null &&
                            post.authorAvatarUrl!.isNotEmpty)
                        ? NetworkImage(post.authorAvatarUrl!) as ImageProvider
                        : null,
                    child: (post.authorAvatarUrl == null ||
                            post.authorAvatarUrl!.isEmpty)
                        ? Text(
                            post.authorName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 1:1 post image ────────────────────────────────────────────
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.primaryLight),
                    ),
                  ),
                ),
              ),
            ],

            // ── Classification result badge ────────────────────────────────
            /// Shown only when the post carries a classification result.
            /// Displays the palm type and confidence score in a tinted chip.
            if (post.classification != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      post.classification!.predictedType,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${post.classification!.confidencePercent}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Optional caption ──────────────────────────────────────────
            if (post.caption != null && post.caption!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(post.caption!),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Like & Comment action row ─────────────────────────────────
            Row(
              children: [
                /// Like button — triggers optimistic update via [FeedProvider].
                _ActionButton(
                  icon: post.likedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.likedByMe ? Colors.red : AppColors.textSecondary,
                  label: l10n.likes(post.likesCount),
                  onTap: () =>
                      context.read<FeedProvider>().toggleLike(index),
                ),
                const SizedBox(width: 16),

                /// Comment button — opens the [CommentSheet] bottom sheet.
                _ActionButton(
                  icon:  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textSecondary,
                  label: l10n.comments(post.commentsCount),
                  onTap: () => _openComments(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small reusable icon + label button used for like and comment actions.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}


