// ─────────────────────────────────────────────
// lib/providers/profile_provider.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/feed_service.dart';

enum ProfileStatus { idle, loading, success, error }

class ProfileProvider extends ChangeNotifier {
  final _service = ProfileService();

  // ── Viewed profile state ──────────────────────────────────────────────────
  UserModel?      _profile;
  List<PostModel> _posts    = [];
  ProfileStatus   _status   = ProfileStatus.idle;
  String?         _errorKey;

  // ── Followers / Following lists ───────────────────────────────────────────
  List<UserModel> _followers      = [];
  List<UserModel> _following      = [];
  bool            _followersLoading = false;
  bool            _followingLoading = false;

  UserModel?      get profile    => _profile;
  List<PostModel> get posts      => List.unmodifiable(_posts);
  ProfileStatus   get status     => _status;
  String?         get errorKey   => _errorKey;
  bool            get isLoading  => _status == ProfileStatus.loading;

  List<UserModel> get followers        => List.unmodifiable(_followers);
  List<UserModel> get following        => List.unmodifiable(_following);
  bool            get followersLoading => _followersLoading;
  bool            get followingLoading => _followingLoading;

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

  /// Deletes a user's post permanently from the profile feed natively.
  Future<void> deletePost(int postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final removedPost = _posts[idx];
    _posts.removeAt(idx);
    
    if (_profile != null) {
      _profile = _profile!.copyWith(postCount: _profile!.postCount - 1);
    }
    notifyListeners();

    try {
      await FeedService().deletePost(postId);
    } catch (e) {
      _posts.insert(idx, removedPost);
      if (_profile != null) {
        _profile = _profile!.copyWith(postCount: _profile!.postCount + 1);
      }
      _errorKey = e.toString();
      notifyListeners();
    }
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

  /// Toggles follow/unfollow for the currently viewed profile.
  Future<void> toggleFollow() async {
    if (_profile == null) return;
    final targetId = _profile!.id;
    try {
      final result = await _service.toggleFollow(targetId);
      final nowFollowing = result['is_following'] as bool;
      final newCount     = result['followers_count'] as int;
      _profile = _profile!.copyWith(
        isFollowing:    nowFollowing,
        followersCount: newCount,
      );
      notifyListeners();
    } catch (_) {}
  }

  /// Loads followers list for [userId].
  Future<void> loadFollowers(int userId) async {
    _followersLoading = true;
    notifyListeners();
    try {
      _followers = await _service.fetchFollowers(userId);
    } catch (_) {
      _followers = [];
    }
    _followersLoading = false;
    notifyListeners();
  }

  /// Loads following list for [userId].
  Future<void> loadFollowing(int userId) async {
    _followingLoading = true;
    notifyListeners();
    try {
      _following = await _service.fetchFollowing(userId);
    } catch (_) {
      _following = [];
    }
    _followingLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorKey = null;
    _status   = ProfileStatus.idle;
    notifyListeners();
  }
}
