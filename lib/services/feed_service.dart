// ─────────────────────────────────────────────
// lib/services/feed_service.dart  (cross-platform: web + mobile + desktop)
// ─────────────────────────────────────────────
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/classification_result_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FeedService {
  Future<Map<String, String>> _authJsonHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetches all community posts (newest first).
  Future<List<PostModel>> fetchPosts() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.posts),
        headers: await _authJsonHeaders(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  /// Creates a new post with the classification result and optional image.
  /// Uses XFile which is cross-platform (web + mobile + desktop).
  Future<PostModel> createPost({
    required ClassificationResult result,
    String? caption,
    XFile?  imageXFile,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.posts),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['predicted_type']   = result.predictedType
        ..fields['confidence_score'] = result.confidenceScore.toString();

      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      if (imageXFile != null) {
        final bytes    = await imageXFile.readAsBytes();
        final filename = imageXFile.name.isNotEmpty ? imageXFile.name : 'image.jpg';
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 201) {
        return PostModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  /// Toggles like on a post.
  Future<void> toggleLike(int postId) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.postLike(postId)),
        headers: await _authJsonHeaders(),
      );
      if (res.statusCode != 200) throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  /// Fetches comments for a post.
  Future<List<CommentModel>> fetchComments(int postId) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.postComments(postId)),
        headers: await _authJsonHeaders(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  /// Adds a comment to a post.
  Future<CommentModel> addComment({
    required int    postId,
    required String body,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.postComments(postId)),
        headers: await _authJsonHeaders(),
        body: jsonEncode({'body': body}),
      );
      if (res.statusCode == 201) {
        return CommentModel.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  /// Fetches recommended users based on Adamic-Adar logic
  Future<List<UserModel>> fetchRecommendations() async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.recommendations),
        headers: await _authJsonHeaders(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return []; // Return empty list on non-200 rather than crashing the feed
    } catch (_) {
      return []; // Silently fallback to no recommendations on error
    }
  }
}