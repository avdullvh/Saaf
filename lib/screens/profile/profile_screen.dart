// ─────────────────────────────────────────────
// lib/screens/profile/profile_screen.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../feed/post_detail_screen.dart';
import 'edit_profile_screen.dart';

// ── Own profile body (inside ShellScreen IndexedStack, tab 2) ────────────────
class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});
  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ProfileProvider>().loadOwnProfile(userId);
        context.read<ProfileProvider>().loadProfile(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    return _ProfileView(
      user:         profile.ownProfile ?? auth.user,
      posts:        profile.posts,
      isOwnProfile: true,
      isLoading:    profile.isLoading,
    );
  }
}

// ── Full-page profile for other users ───────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final auth    = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final isOwn   = auth.user?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile.profile == null
              ? Center(child: Text(l10n.profileNotFound))
              : _ProfileView(
                  user:         profile.profile,
                  posts:        profile.posts,
                  isOwnProfile: isOwn,
                  isLoading:    false,
                ),
    );
  }
}

// ── Shared profile UI ─────────────────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  final UserModel? user;
  final List<PostModel> posts;
  final bool isOwnProfile;
  final bool isLoading;

  const _ProfileView({
    required this.user,
    required this.posts,
    required this.isOwnProfile,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading || user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: (user!.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user!.avatarUrl!) as ImageProvider
                          : null,
                      child: (user!.avatarUrl == null || user!.avatarUrl!.isEmpty)
                          ? Text(
                              user!.fullName.isNotEmpty
                                  ? user!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    if (isOwnProfile)
                      GestureDetector(
                        onTap: () => _goEdit(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  user!.fullName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Post count chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${posts.isNotEmpty ? posts.length : user!.postCount} ${l10n.posts}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bio
                if (user!.bio != null && user!.bio!.isNotEmpty)
                  Text(
                    user!.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  )
                else if (isOwnProfile)
                  GestureDetector(
                    onTap: () => _goEdit(context),
                    child: Text(
                      l10n.addBioHint,
                      style: TextStyle(
                          color: AppColors.primaryLight,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),

                // Edit Profile button (own profile only)
                if (isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.editProfile),
                      onPressed: () => _goEdit(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Posts section header
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      l10n.posts,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),
        ),

        // Posts list
        posts.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_outlined,
                        size: 64,
                        color: AppColors.primaryLight.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noPostsProfile,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PostTile(post: posts[i]),
                  childCount: posts.length,
                ),
              ),
      ],
    );
  }

  void _goEdit(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.id;
    if (uid == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userId: uid),
      ),
    );
  }
}

// ── Individual post tile shown in the profile ────────────────────────────────
class _PostTile extends StatelessWidget {
  final PostModel post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56,
            height: 56,
            child: (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                ? Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.eco_rounded,
                          color: AppColors.primary, size: 26),
                    ),
                  )
                : Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.eco_rounded,
                        color: AppColors.primary, size: 26),
                  ),
          ),
        ),
        title: post.classification != null
            ? Text(
                post.classification!.predictedType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : Text(post.caption ?? 'Post'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.classification != null)
              Text(post.classification!.confidencePercent,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            if (post.caption != null && post.caption!.isNotEmpty)
              Text(
                post.caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${post.likesCount}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        ),
      ),
    );
  }
}
