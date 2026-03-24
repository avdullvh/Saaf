import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/profile_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/profile_screen.dart';

class RecommendationCard extends StatefulWidget {
  final UserModel user;

  const RecommendationCard({super.key, required this.user});

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  late bool _isFollowing;
  bool _isLoading = false;
  final _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isFollowing;
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    // Optimistic update
    final previousState = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);
    
    try {
      final res = await _profileService.toggleFollow(widget.user.id);
      if (mounted) {
        setState(() {
          _isFollowing = res['is_following'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isFollowing = previousState;
          _isLoading = false;
        });
      }
    }
  }

  void _goToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primaryLight.withOpacity(0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.peopleYouMayKnow,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _goToProfile,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(widget.user.avatarUrl!) as ImageProvider
                        : null,
                    child: (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty)
                        ? Text(
                            widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
                          Text(
                            widget.user.bio!,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                            '@user${widget.user.id}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isFollowing
                      ? OutlinedButton(
                          onPressed: _toggleFollow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            minimumSize: const Size(88, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(l10n.unfollow, style: const TextStyle(fontSize: 13)),
                        )
                      : ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            minimumSize: const Size(88, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(l10n.follow, style: const TextStyle(fontSize: 13)),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
