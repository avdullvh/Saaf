import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/classification_result_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/feed_service.dart';

enum FeedStatus { idle, loading, success, error }

class FeedProvider extends ChangeNotifier {
  final _service = FeedService();

  List<PostModel> _posts           = [];
  List<UserModel> _recommendations = [];
  FeedStatus      _status          = FeedStatus.idle;
  String?         _errorKey;

  List<PostModel> get posts           => List.unmodifiable(_posts);
  List<UserModel> get recommendations => List.unmodifiable(_recommendations);
  FeedStatus      get status    => _status;
  String?         get errorKey  => _errorKey;
  bool            get isLoading => _status == FeedStatus.loading;

  /// Loads the community feed posts from [FeedService].
  /// Transitions through loading → success/error and notifies listeners
  /// so the UI rebuilds accordingly.
  Future<void> loadPosts() async {
    _status   = FeedStatus.loading;
    _errorKey = null;
    notifyListeners();
    try {
      // Fetch posts first
      _posts  = await _service.fetchPosts();
      _status = FeedStatus.success;
      notifyListeners();
      
      // Lazily fetch recommendations so we don't block the feed from showing
      _recommendations = await _service.fetchRecommendations();
      notifyListeners();
    } catch (e) {
      _errorKey = e.toString();
      _status   = FeedStatus.error;
      notifyListeners();
    }
  }

  /// Creates a new feed post from a [ClassificationResult] and an optional
  /// [caption], then prepends it to the top of the local posts list so the
  /// user sees their post immediately without a full reload.
  Future<bool> shareClassificationToFeed({
    required ClassificationResult result,
    String? caption,
    XFile?  imageXFile,
  }) async {
    try {
      final newPost = await _service.createPost(
        result:     result,
        caption:    caption,
        imageXFile: imageXFile,
      );
      _posts = [newPost, ..._posts];
      notifyListeners();
      return true;
    } catch (e) {
      _errorKey = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Optimistically toggles the like state of the post at [index] in the
  /// local list before the server confirms, giving instant UI feedback.
  /// Reverts the change if the server call fails.
  Future<void> toggleLike(int index) async {
    final post    = _posts[index];
    final wasLiked = post.likedByMe;

    /// Apply the optimistic update immediately.
    _posts[index] = post.copyWith(
      likedByMe:  !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    notifyListeners();

    try {
      await _service.toggleLike(post.id);
    } catch (_) {
      /// Revert to the original state if the server call fails.
      _posts[index] = post;
      notifyListeners();
    }
  }

  /// Fetches the comments for the post identified by [postId] from
  /// [FeedService] and returns them as a list.
  /// Throws on error so the caller (CommentSheet) can handle it locally.
  Future<List<CommentModel>> fetchComments(int postId) =>
      _service.fetchComments(postId);

  /// Submits a new comment to the post identified by [postId], then
  /// increments the local comment count so the feed card updates instantly.
  Future<CommentModel> addComment({
    required int    postId,
    required String body,
  }) async {
    final comment = await _service.addComment(postId: postId, body: body);

    /// Find the post in the local list and bump its comment count by 1.
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final p      = _posts[idx];
      _posts[idx]  = p.copyWith(likesCount: p.likesCount); // trigger rebuild
      /// Manually rebuild with updated commentsCount via a fresh PostModel.
      _posts[idx] = PostModel(
        id:              p.id,
        authorId:        p.authorId,
        authorName:      p.authorName,
        authorAvatarUrl: p.authorAvatarUrl,
        caption:         p.caption,
        imageUrl:        p.imageUrl,
        classification:  p.classification,
        likesCount:      p.likesCount,
        likedByMe:       p.likedByMe,
        commentsCount:   p.commentsCount + 1,
        createdAt:       p.createdAt,
      );
      notifyListeners();
    }
    return comment;
  }

  /// Deletes a post locally first (optimistic UI), then calls the service.
  /// If the server call fails, it reverts the local deletion.
  Future<void> deletePost(int postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final removedPost = _posts[idx];
    _posts.removeAt(idx);
    notifyListeners();

    try {
      await _service.deletePost(postId);
    } catch (e) {
      _posts.insert(idx, removedPost);
      _errorKey = e.toString();
      notifyListeners();
    }
  }

  /// Clears any stored error key and resets status to idle.
  void clearError() {
    _errorKey = null;
    _status   = FeedStatus.idle;
    notifyListeners();
  }

  /// Wipes all cached posts and resets to idle.
  /// Call on logout so the next user always gets a fresh feed
  /// with up-to-date author avatar URLs.
  void clear() {
    _posts           = [];
    _recommendations = [];
    _status          = FeedStatus.idle;
    _errorKey        = null;
    notifyListeners();
  }
}