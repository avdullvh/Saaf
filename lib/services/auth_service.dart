// ─────────────────────────────────────────────
// lib/services/auth_service.dart
// ─────────────────────────────────────────────
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  // ── Login ────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        await TokenStorage.saveTokens(
          access:  body['access']  as String,
          refresh: body['refresh'] as String,
        );
        return UserModel.fromJson(body['user'] as Map<String, dynamic>);
      }
      if (res.statusCode == 401) throw 'errorInvalidCredentials';
      throw 'errorGeneric';
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email':     email,
          'password':  password,
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        await TokenStorage.saveTokens(
          access:  body['access']  as String,
          refresh: body['refresh'] as String,
        );
        return UserModel.fromJson(body['user'] as Map<String, dynamic>);
      }
      // Show any validation error from Django
      final detail = body['detail']
          ?? body['email']?.first
          ?? body['password']?.first
          ?? 'errorGeneric';
      throw detail.toString();
    } on SocketException {
      throw 'errorNetwork';
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async => TokenStorage.clearTokens();
}