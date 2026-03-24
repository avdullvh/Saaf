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
    final user    = profile.ownProfile ?? auth.user;

    return _ProfileView(
      user:         user,
      posts:        profile.posts,
      isOwnProfile: true,
      isLoading:    profile.isLoading,
      isFollowing:       false,
      onFollowToggle:    null,
      provider:          profile,
    );
  }
}

// ── Full-page profile for other users ────────────────────────────────────────
// Each instance gets its OWN ProfileProvider so it never touches
// the global one used by ProfileBody.
class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileProvider _localProvider;

  @override
  void initState() {
    super.initState();
    _localProvider = ProfileProvider();
    // Kick off load immediately — no postFrameCallback needed since the
    // provider is created here before build, so it can be read right away.
    Future.microtask(() => _localProvider.loadProfile(widget.userId));
  }

  @override
  void dispose() {
    _localProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    return ChangeNotifierProvider<ProfileProvider>.value(
      value: _localProvider,
      child: Consumer<ProfileProvider>(
        builder: (ctx, profile, _) {
          final isOwn = auth.user?.id == widget.userId;
          final isEffectivelyLoading =
              profile.status == ProfileStatus.idle ||
              profile.status == ProfileStatus.loading;

          return Scaffold(
            appBar: AppBar(title: Text(l10n.profileTitle)),
            body: isEffectivelyLoading
                ? const Center(child: CircularProgressIndicator())
                : profile.profile == null
                    ? Center(child: Text(l10n.profileNotFound))
                    : _ProfileView(
                        user:         profile.profile!,
                        posts:        profile.posts,
                        isOwnProfile: isOwn,
                        isLoading:    false,
                        isFollowing:       profile.profile!.isFollowing,
                        onFollowToggle:    isOwn ? null : () => _localProvider.toggleFollow(),
                        provider:          profile,
                      ),
          );
        },
      ),
    );
  }
}

// ── Shared profile UI ─────────────────────────────────────────────────────────
// All dynamic state is passed as plain parameters — no provider look-ups
// inside this subtree, so it works regardless of which provider is in scope.
class _ProfileView extends StatelessWidget {
  final UserModel? user;
  final List<PostModel> posts;
  final bool isOwnProfile;
  final bool isLoading;

  // Follow-related params (null-safe: unused for own profile)
  final bool           isFollowing;
  final VoidCallback?  onFollowToggle;
  final ProfileProvider provider;

  const _ProfileView({
    required this.user,
    required this.posts,
    required this.isOwnProfile,
    required this.isLoading,
    required this.isFollowing,
    required this.onFollowToggle,
    required this.provider,
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
                // ── Avatar ──────────────────────────────────────────────────
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
                              user!.fullName.isNotEmpty ? user!.fullName[0].toUpperCase() : '?',
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
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Name + optional Follow button ────────────────────────────
                if (!isOwnProfile && onFollowToggle != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user!.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FollowButton(
                        isFollowing:   isFollowing,
                        onTap:         onFollowToggle!,
                      ),
                    ],
                  )
                else
                  Text(
                    user!.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 12),

                // ── Stats row ────────────────────────────────────────────────
                _StatsRow(
                  user:            user!,
                  posts:           posts,
                  l10n:            l10n,
                  onTapFollowers:  () => _showFollowList(
                    context,
                    title:    l10n.followers,
                    type:     _FollowListType.followers,
                  ),
                  onTapFollowing:  () => _showFollowList(
                    context,
                    title:    l10n.following,
                    type:     _FollowListType.following,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Bio ──────────────────────────────────────────────────────
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
                          color: AppColors.primaryLight, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Edit Profile button ──────────────────────────────────────
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
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Posts header ─────────────────────────────────────────────
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

        // ── Posts list ───────────────────────────────────────────────────────
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
      MaterialPageRoute(builder: (_) => EditProfileScreen(userId: uid)),
    );
  }

  void _showFollowList(
    BuildContext context, {
    required String         title,
    required _FollowListType type,
  }) {
    if (user == null) return;
    final targetId = user!.id;
    if (type == _FollowListType.followers) {
      provider.loadFollowers(targetId);
    } else {
      provider.loadFollowing(targetId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      // Use ListenableBuilder with the provider, so it rebuilds when load completes
      builder: (_) => ListenableBuilder(
        listenable: provider,
        builder: (ctx, _) {
          final users = type == _FollowListType.followers
              ? provider.followers
              : provider.following;
          final loading = type == _FollowListType.followers
              ? provider.followersLoading
              : provider.followingLoading;
              
          return _FollowListSheet(
            title:   title,
            type:    type,
            users:   users,
            loading: loading,
          );
        },
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final UserModel       user;
  final List<PostModel> posts;
  final AppLocalizations l10n;
  final VoidCallback    onTapFollowers;
  final VoidCallback    onTapFollowing;

  const _StatsRow({
    required this.user,
    required this.posts,
    required this.l10n,
    required this.onTapFollowers,
    required this.onTapFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final postCount = posts.isNotEmpty ? posts.length : user.postCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(label: l10n.posts,     count: postCount,          onTap: null),
        _StatDivider(),
        _StatChip(label: l10n.followers, count: user.followersCount, onTap: onTapFollowers),
        _StatDivider(),
        _StatChip(label: l10n.following, count: user.followingCount, onTap: onTapFollowing),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String      label;
  final int         count;
  final VoidCallback? onTap;

  const _StatChip({required this.label, required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: onTap != null ? AppColors.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.textSecondary.withOpacity(0.3),
    );
  }
}

// ── Stateless Follow / Unfollow button ───────────────────────────────────────
// Receives state as parameters — no provider look-up here.
class _FollowButton extends StatelessWidget {
  final bool          isFollowing;
  final VoidCallback  onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isFollowing) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: const Size(88, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(l10n.unfollow, style: const TextStyle(fontSize: 13)),
      );
    } else {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: const Size(88, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(l10n.follow, style: const TextStyle(fontSize: 13)),
      );
    }
  }
}

// ── Bottom-sheet: list of followers or following users ────────────────────────
// Pure display — accepts data as constructor params, no provider access.
enum _FollowListType { followers, following }

class _FollowListSheet extends StatelessWidget {
  final String          title;
  final _FollowListType type;
  final List<UserModel> users;
  final bool            loading;

  const _FollowListSheet({
    required this.title,
    required this.type,
    required this.users,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? Center(
                        child: Text('–',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: users.length,
                        itemBuilder: (_, i) => _UserTile(user: users[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Individual user tile inside the follow list ───────────────────────────────
class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
            ? NetworkImage(user.avatarUrl!) as ImageProvider
            : null,
        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
            ? Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: (user.bio != null && user.bio!.isNotEmpty)
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      onTap: () {
        // Capture navigator before popping so context stays valid.
        final nav = Navigator.of(context);
        nav.pop();
        nav.push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: user.id),
          ),
        );
      },
    );
  }
}

// ── Individual post tile in the profile ──────────────────────────────────────
class _PostTile extends StatelessWidget {
  final PostModel post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final isMyPost = post.authorId == context.read<AuthProvider>().user?.id;
    final l10n = AppLocalizations.of(context)!;

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
            ? Text(post.classification!.predictedType,
                style: const TextStyle(fontWeight: FontWeight.bold))
            : Text(post.caption ?? 'Post'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.classification != null)
              Text(post.classification!.confidencePercent,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
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
            if (isMyPost) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: Column(
                              children: [
                                Text(
                                  l10n.deletePostTitle ?? 'Delete post?',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.deletePostConfirm ?? 'After this it will be permanently deleted.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          InkWell(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              alignment: Alignment.center,
                              child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          InkWell(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              alignment: Alignment.center,
                              child: Text(l10n.cancel ?? 'Cancel', style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    context.read<ProfileProvider>().deletePost(post.id);
                  }
                },
              ),
            ],
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        ),
      ),
    );
  }
}
