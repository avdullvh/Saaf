// ─────────────────────────────────────────────
// lib/providers/theme_provider.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
