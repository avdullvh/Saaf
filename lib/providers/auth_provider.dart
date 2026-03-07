import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/utils/token_storage.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel?  _user;
  AuthStatus  _status = AuthStatus.idle;
  String?     _errorKey; // l10n key e.g. 'errorInvalidCredentials'

  UserModel?  get user            => _user;
  AuthStatus  get status          => _status;
  String?     get errorKey        => _errorKey;
  bool        get isAuthenticated => _user != null;
  bool        get isLoading       => _status == AuthStatus.loading;

  // ── Called once on app start to restore session ───────────────────────
  Future<void> tryRestoreSession() async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      // With a real backend you'd verify / refresh the token here.
      // For mock mode we just flag as authenticated with a placeholder user.
      _user = UserModel(id: 0, fullName: 'Returning User', email: '');
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user    = await _service.login(email: email, password: password);
      _status  = AuthStatus.success;
      _errorKey = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorKey = e.toString();
      _status   = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _service.register(
        fullName: fullName,
        email:    email,
        password: password,
      );
      _status   = AuthStatus.success;
      _errorKey = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorKey = e.toString();
      _status   = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    _user     = null;
    _status   = AuthStatus.idle;
    _errorKey = null;
    notifyListeners();
  }

  void clearError() {
    _errorKey = null;
    _status   = AuthStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _status   = AuthStatus.loading;
    _errorKey = null;
    notifyListeners();
  }
}