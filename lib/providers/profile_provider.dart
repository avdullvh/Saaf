// ─────────────────────────────────────────────
// lib/providers/profile_provider.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

enum ProfileStatus { idle, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final _service = ProfileService();

  // ── Viewed profile state ──────────────────────────────────────────────────
  UserModel?      _profile;
  List<PostModel> _posts    = [];
  ProfileStatus   _status   = ProfileStatus.idle;
  String?         _errorKey;

  UserModel?      get profile   => _profile;
  List<PostModel> get posts     => List.unmodifiable(_posts);
  ProfileStatus   get status    => _status;
  String?         get errorKey  => _errorKey;
  bool            get isLoading => _status == ProfileStatus.loading;

  // ── Own profile state (kept in sync after edits) ─────────────────────────
  UserModel? _ownProfile;
  UserModel? get ownProfile => _ownProfile;

  /// Loads both profile info and posts for the given [userId].
  Future<void> loadProfile(int userId) async {
    _status   = ProfileStatus.loading;
    _errorKey = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchProfile(userId),
        _service.fetchUserPosts(userId),
      ]);
      _profile = results[0] as UserModel;
      _posts   = results[1] as List<PostModel>;
      _status  = ProfileStatus.success;
    } catch (e) {
      _errorKey = e.toString();
      _status   = ProfileStatus.error;
    }
    notifyListeners();
  }

  /// Seeds the provider with the logged-in user data immediately after login.
  void seedOwnProfile(UserModel user) {
    _ownProfile = user;
    notifyListeners();
  }

  /// Loads the logged-in user's own profile (fetches fresh data from service).
  Future<void> loadOwnProfile(int userId) async {
    try {
      _ownProfile = await _service.fetchProfile(userId);
      notifyListeners();
    } catch (_) {}
  }

  /// Updates the current user's name and bio via [ProfileService].
  Future<bool> updateProfile({
    required int    userId,
    required String fullName,
    required String bio,
    XFile?          avatarXFile,
  }) async {
    try {
      final updated = await _service.updateProfile(
        userId:      userId,
        fullName:    fullName,
        bio:         bio,
        avatarXFile: avatarXFile,
      );
      _ownProfile = updated;
      if (_profile?.id == userId) _profile = updated;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    _errorKey = null;
    _status   = ProfileStatus.idle;
    notifyListeners();
  }
}
