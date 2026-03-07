// ─────────────────────────────────────────────
// lib/core/constants/api_constants.dart
// ─────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Auth
  static const String login    = '$baseUrl/auth/login/';
  static const String register = '$baseUrl/auth/register/';
  static const String refresh  = '$baseUrl/auth/token/refresh/';

  // Classification
  static const String classify = '$baseUrl/classify/';

  // Feed
  static const String posts = '$baseUrl/posts/';
  static String postLike(int id)     => '$baseUrl/posts/$id/like/';
  static String postComments(int id) => '$baseUrl/posts/$id/comments/';

  // Profile
  static String profile(int id)      => '$baseUrl/profile/$id/';
  static String profilePosts(int id) => '$baseUrl/profile/$id/posts/';
}
