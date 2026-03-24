import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/classification_provider.dart';
import 'result_screen.dart';
import '../../l10n/generated/app_localizations.dart';

/// Body widget used inside ShellScreen's IndexedStack (tab 0 – Classify).
/// All AppBar/BottomNav is handled by ShellScreen.
class UploadBody extends StatelessWidget {
  const UploadBody({super.key});

  Future<void> _pickImage(BuildContext ctx, ImageSource source) async {
    final picker = ImagePicker();
    final l10n   = AppLocalizations.of(ctx)!;
    try {
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (xFile == null) return;
      // setImage is now async — it converts HEIC→JPEG before storing.
      await ctx.read<ClassificationProvider>().setImage(xFile);
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.errorImagePick)),
        );
      }
    }
  }

  Future<void> _classify(BuildContext ctx) async {
    final provider = ctx.read<ClassificationProvider>();
    final l10n     = AppLocalizations.of(ctx)!;

    await provider.classify();

    if (!ctx.mounted) return;
    if (provider.hasResult) {
      Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
    } else {
      final errKey = provider.errorKey ?? 'errorGeneric';
      final msg    = errKey == 'errorNetwork'
          ? l10n.errorNetwork
          : l10n.errorGeneric;
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n       = AppLocalizations.of(context)!;
    final classifier = context.watch<ClassificationProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showPickerSheet(context),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: classifier.selectedImage == null
                      ? _PlaceholderBox(label: l10n.uploadPrompt)
                      : _ImagePreview(
                          bytes:    classifier.previewBytes,
                          onRePick: () => _showPickerSheet(context),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceButton(
                    icon:  Icons.camera_alt_outlined,
                    label: l10n.camera,
                    onTap: () => _pickImage(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceButton(
                    icon:  Icons.photo_library_outlined,
                    label: l10n.gallery,
                    onTap: () => _pickImage(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (classifier.selectedImage == null ||
                      classifier.isLoading)
                  ? null
                  : () => _classify(context),
              child: classifier.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.classifying),
                      ],
                    )
                  : Text(l10n.classifyButton),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ctx, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ctx, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _PlaceholderBox extends StatelessWidget {
  final String label;
  const _PlaceholderBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.4),
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 72, color: AppColors.primaryLight),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onRePick;
  const _ImagePreview({required this.bytes, required this.onRePick});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: bytes != null
              // Image.memory works on all platforms (web + native) and
              // always receives browser-safe JPEG bytes from the provider.
              ? Image.memory(bytes!, fit: BoxFit.cover)
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          bottom: 12, right: 12,
          child: GestureDetector(
            onTap: onRePick,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon:  Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}