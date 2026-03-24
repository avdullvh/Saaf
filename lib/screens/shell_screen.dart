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
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const UploadBody(),
      const FeedBody(),
      const ProfileBody(),
    ];
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
    final l10n   = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>();
    // NOTE: ThemeProvider is NOT watched here — only read in the Consumer
    // below to avoid rebuilding the entire Scaffold+IndexedStack on theme
    // toggle (which races with MaterialApp's rebuild and causes GlobalKey
    // collisions in the BottomNavigationBar's ink renderers).

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Dark mode toggle (Left) ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Consumer<ThemeProvider>(
                    builder: (_, tp, __) => IconButton(
                      icon: Icon(
                        tp.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      ),
                      tooltip: tp.isDark ? l10n.lightMode : l10n.darkMode,
                      onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                    ),
                  ),
                ),
                // ── Title ──
                const Text(
                  'Saaf',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                // ── Right Actions (Lang & Logout) ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 40),
                        ),
                        onPressed: () => context.read<LocaleProvider>().setLocale(
                          locale.isArabic ? const Locale('en') : const Locale('ar'),
                        ),
                        child: Text(
                          locale.isArabic ? 'EN' : 'ع',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: l10n.logout,
                        onPressed: () async {
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
                ),
              ],
            ),
          ),
        ),
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
