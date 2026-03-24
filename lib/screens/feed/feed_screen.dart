import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/feed_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/recommendation_card.dart';
import '../../l10n/generated/app_localizations.dart';

/// Body widget used inside ShellScreen's IndexedStack (tab 1 – Feed).
/// All AppBar/BottomNav is handled by ShellScreen.
class FeedBody extends StatefulWidget {
  const FeedBody({super.key});

  @override
  State<FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<FeedBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadPosts();
    });
  }

  Future<void> _onRefresh() =>
      context.read<FeedProvider>().loadPosts();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feed = context.watch<FeedProvider>();
    return _buildBody(feed, l10n);
  }

  Widget _buildBody(FeedProvider feed, AppLocalizations l10n) {
    if (feed.isLoading && feed.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feed.status == FeedStatus.error && feed.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              feed.errorKey == 'errorNetwork'
                  ? l10n.errorNetwork
                  : l10n.errorGeneric,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon:  const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (feed.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined,
                size: 72,
                color: AppColors.primaryLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noPostsYet,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: feed.posts.length,
        itemBuilder: (_, i) {
          final postCard = PostCard(
            post:  feed.posts[i],
            index: i,
          );
          
          // Every 6 posts (index 5, 11, 17...), inject a recommendation card below it
          if (i > 0 && (i + 1) % 6 == 0 && feed.recommendations.isNotEmpty) {
            // Cycle through recommendations
            final recIndex = ((i + 1) ~/ 6 - 1) % feed.recommendations.length;
            final user = feed.recommendations[recIndex];
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                postCard,
                RecommendationCard(user: user),
              ],
            );
          }
          
          return postCard;
        },
      ),
    );
  }
}