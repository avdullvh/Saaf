// ─────────────────────────────────────────────
// lib/screens/shell_screen.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/classification_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import 'classification/upload_screen.dart';
import 'feed/feed_screen.dart';
import 'profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../l10n/generated/app_localizations.dart';

class ShellScreen extends StatefulWidget {
  final int initialIndex;
  const ShellScreen({super.key, this.initialIndex = 0});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _currentIndex;

  static const List<Widget> _pages = [
    UploadBody(),
    FeedBody(),
    ProfileBody(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ProfileProvider>().seedOwnProfile(user);
        context.read<ProfileProvider>().loadOwnProfile(user.id);
      }
    });
  }

  void _onTap(int i) {
    // Reset classify state when navigating AWAY from the classify tab.
    if (_currentIndex == 0 && i != 0) {
      context.read<ClassificationProvider>().reset();
    }
    // Refresh the feed when tapping the Feed tab so avatar updates are visible.
    if (i == 1) {
      context.read<FeedProvider>().loadPosts();
    }
    // Reload profile posts when switching TO the profile tab.
    if (i == 2) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ProfileProvider>().loadProfile(userId);
      }
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n          = AppLocalizations.of(context)!;
    final locale        = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();



    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        automaticallyImplyLeading: false,
        // ── Dark mode toggle (top-left) ───────────────────────────────────
        leading: IconButton(
          icon: Icon(
            themeProvider.isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          tooltip: themeProvider.isDark ? l10n.lightMode : l10n.darkMode,
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () => context.read<LocaleProvider>().setLocale(
              locale.isArabic ? const Locale('en') : const Locale('ar'),
            ),
            child: Text(
              locale.isArabic ? 'EN' : 'ع',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
          onPressed: () async {
              // Clear all cached state before logging out so the
              // next user gets a completely fresh feed with correct avatars.
              context.read<ClassificationProvider>().reset();
              context.read<FeedProvider>().clear();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const LoginScreen(),
                    transitionDuration: Duration.zero,
                  ),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),

      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        onTap: _onTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.eco_rounded),
            label: l10n.tabClassify,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_outlined),
            label: l10n.tabFeed,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
