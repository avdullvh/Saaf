// ─────────────────────────────────────────────
// lib/screens/profile/edit_profile_screen.dart  (cross-platform)
// ─────────────────────────────────────────────
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final int userId;
  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey  = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;

  XFile?     _avatarXFile;   // picked file (cross-platform)
  Uint8List? _avatarBytes;   // preview bytes loaded from XFile
  bool       _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().ownProfile;
    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _bioCtrl  = TextEditingController(text: profile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile == null) return;
    // Load bytes immediately for preview — works on web + mobile + desktop.
    final bytes = await xFile.readAsBytes();
    setState(() {
      _avatarXFile = xFile;
      _avatarBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;

    final ok = await context.read<ProfileProvider>().updateProfile(
      userId:      widget.userId,
      fullName:    _nameCtrl.text.trim(),
      bio:         _bioCtrl.text.trim(),
      avatarXFile: _avatarXFile,
    );

    setState(() => _saving = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated)),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdateFailed)),
      );
    }
  }

  /// Builds the avatar preview. Priority:
  ///   1. Newly picked bytes (in-memory, cross-platform)
  ///   2. Existing avatar URL from server
  ///   3. Fallback initial letter
  Widget _buildAvatar() {
    final profile = context.read<ProfileProvider>().ownProfile;
    final existingUrl = profile?.avatarUrl;

    ImageProvider? imageProvider;
    if (_avatarBytes != null) {
      imageProvider = MemoryImage(_avatarBytes!);
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      imageProvider = NetworkImage(existingUrl);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(
                  _nameCtrl.text.isNotEmpty
                      ? _nameCtrl.text[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        GestureDetector(
          onTap: _pickAvatar,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ───────────────────────────────────────────────────
              Center(child: _buildAvatar()),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Change photo'),
                ),
              ),
              const SizedBox(height: 20),

              // ── Full name ─────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.nameRequired
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ── Bio ───────────────────────────────────────────────────────
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: l10n.bio,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.info_outline),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Save ──────────────────────────────────────────────────────
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white,
                        ),
                      )
                    : Text(l10n.saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
