import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/classification_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classification_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/profile_provider.dart';
import '../../screens/shell_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  /// Resolves a color for the confidence progress bar based on the score:
  /// - Green  → high confidence (≥ 0.95)
  /// - Amber  → low confidence  (< 0.95)
  Color _confidenceColor(double score) {
    if (score >= 0.95) return AppColors.primary;
    return AppColors.accent;
  }

  /// Returns the display label for the predicted palm type.
  /// Shows the actual classification name only when confidence is ≥ 0.95,
  /// otherwise returns "Unknown" to avoid misleading the farmer.
  String _resolvedType(ClassificationResult result) {
    if (result.confidenceScore >= 0.95) return result.predictedType;
    return 'Unknown';
  }

  /// Submits a new post to the community feed that carries the current
  /// classification result and an optional caption entered by the user.
  /// Shows a success or error snackbar upon completion.
  Future<void> _shareToFeed(
    BuildContext ctx,
    ClassificationResult result,
  ) async {
    final l10n     = AppLocalizations.of(ctx)!;
    final captionCtrl = TextEditingController();

    /// Ask the user to optionally type a caption before posting.
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.shareToFeed),
        content: TextField(
          controller: captionCtrl,
          decoration: InputDecoration(hintText: l10n.shareCaption),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(l10n.post),
          ),
        ],
      ),
    );

    if (confirmed != true || !ctx.mounted) return;

    // Pass the XFile directly — cross-platform, no dart:io File needed.
    final xFile = ctx.read<ClassificationProvider>().selectedImage;

    final ok = await ctx.read<FeedProvider>().shareClassificationToFeed(
      result:     result,
      caption:    captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
      imageXFile: xFile,
    );

    if (!ctx.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneric),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Reload own profile so the new post shows in the Profile tab immediately.
    final userId = ctx.read<AuthProvider>().user?.id;
    if (userId != null) {
      ctx.read<ProfileProvider>().loadOwnProfile(userId);
      ctx.read<ProfileProvider>().loadProfile(userId);
    }

    if (!ctx.mounted) return;

    // Show success dialog with Go to Feed / Classify Another options.
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded,
            color: AppColors.primary, size: 48),
        title: Text(l10n.successPost,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          l10n.postSharedMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          // Go to Feed
          ElevatedButton.icon(
            icon: const Icon(Icons.people_alt_outlined),
            label: Text(l10n.goToFeed),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              // Navigate to ShellScreen with Feed tab (index 1) pre-selected.
              Navigator.of(ctx).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                      const ShellScreen(initialIndex: 1),
                  transitionDuration: Duration.zero,
                ),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 8),
          // Classify another
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.classifyAnother),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
            onPressed: () {
              Navigator.of(dCtx).pop();
              ctx.read<ClassificationProvider>().reset();
              Navigator.of(ctx).pop(); // Back to upload screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final result = context.watch<ClassificationProvider>().result!;
    final image  = context.watch<ClassificationProvider>().selectedImage;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Classified image thumbnail ──────────────────────────────
              /// Shows the image that was submitted for classification
              /// so the user can confirm it matches the result.
              if (image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  // Use Image.network for web (XFile.path is a blob URL),
                  // Image.network also works on mobile for local paths via
                  // file:// scheme. Simplest cross-platform approach.
                  child: kIsWeb
                      ? Image.network(
                          image.path,
                          height: 220,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          Uri.file(image.path).toString(),
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => FutureBuilder<List<int>>(
                            future: image.readAsBytes().then((b) => b.toList()),
                            builder: (ctx, snap) {
                              if (snap.hasData) {
                                return Image.memory(
                                  Uint8List.fromList(snap.data!),
                                  height: 220,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const SizedBox(height: 220);
                            },
                          ),
                        ),
                ),

              const SizedBox(height: 24),

              // ── Result card ─────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Palm type label ──
                      Text(
                        l10n.palmType,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      /// Displays the predicted palm variety name if confidence
                      /// is ≥ 0.95, otherwise shows "Unknown" to prevent
                      /// misleading the farmer with a low-confidence result.
                      Text(
                        _resolvedType(result),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (_resolvedType(result) != 'Unknown') ...[
                        const Divider(height: 28),

                        // ── Confidence score ──
                        Text(
                          l10n.confidence,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        /// Animated circular progress indicator representing
                        /// the model's confidence score as a percentage.
                        Center(
                          child: CircularPercentIndicator(
                            radius: 70,
                            lineWidth: 10,
                            percent: result.confidenceScore,
                            animation: true,
                            animationDuration: 800,
                            center: Text(
                              result.confidencePercent,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            progressColor:
                                _confidenceColor(result.confidenceScore),
                            backgroundColor:
                                AppColors.divider,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Share to Feed button ────────────────────────────────────
              /// Opens a caption dialog then publishes the result as a
              /// community feed post via [FeedProvider].
              /// Only visible if the classification is known.
              if (_resolvedType(result) != 'Unknown') ...[
                ElevatedButton.icon(
                  onPressed: () => _shareToFeed(context, result),
                  icon:  const Icon(Icons.share_outlined),
                  label: Text(l10n.shareToFeed),
                ),
                const SizedBox(height: 12),
              ],

              // ── Classify Another button ─────────────────────────────────
              /// Resets [ClassificationProvider] and returns the user to the
              /// upload screen so they can start a fresh classification.
              OutlinedButton.icon(
                onPressed: () {
                  context.read<ClassificationProvider>().reset();
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ShellScreen(),
                      transitionDuration: Duration.zero,
                    ),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.classifyAnother),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}