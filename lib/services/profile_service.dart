// ─────────────────────────────────────────────
// lib/services/profile_service.dart  (cross-platform)
// ─────────────────────────────────────────────
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class ProfileService {
  Future<String?> _token() => TokenStorage.getAccessToken();

  /// Fetches a user's profile by ID.
  Future<UserModel> fetchProfile(int userId) async {
    try {
      final token = await _token();
      final res = await http.get(
        Uri.parse(ApiConstants.profile(userId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
      );
      if (res.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  /// Fetches the posts belonging to a specific user.
  Future<List<PostModel>> fetchUserPosts(int userId) async {
    try {
      final token = await _token();
      final res = await http.get(
        Uri.parse(ApiConstants.profilePosts(userId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
        },
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

  /// Updates name, bio, and optionally avatar (cross-platform XFile).
  Future<UserModel> updateProfile({
    required int    userId,
    required String fullName,
    required String bio,
    XFile?          avatarXFile,
  }) async {
    try {
      final token = await _token();
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(ApiConstants.profile(userId)),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['full_name'] = fullName
        ..fields['bio']       = bio;

      if (avatarXFile != null) {
        final bytes    = await avatarXFile.readAsBytes();
        final filename = avatarXFile.name.isNotEmpty ? avatarXFile.name : 'avatar.jpg';
        request.files.add(http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: filename,
        ));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }
}
