// ─────────────────────────────────────────────
// lib/main.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/classification_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PalmClassifierApp());
}

class PalmClassifierApp extends StatelessWidget {
  const PalmClassifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClassificationProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      // ── ThemeMode is read separately so theme toggles don't rebuild
      //    the entire MaterialApp child tree (which causes ink-renderer
      //    GlobalKey collisions when the nav-bar is remounted).
      child: Selector<ThemeProvider, bool>(
        selector: (_, tp) => tp.isDark,
        builder: (ctx, isDark, _) {
          return Consumer2<LocaleProvider, AuthProvider>(
            builder: (ctx2, localeProvider, authProvider, _) {
              return MaterialApp(
                title: 'Saaf',
                debugShowCheckedModeBanner: false,

                // ── Theme ──
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                // Instant switch — avoids TextStyle lerp crash on inherit mismatch
                // and eliminates the animation window where two subtrees coexist.
                themeAnimationDuration: Duration.zero,

                // ── Localization ──
                locale: localeProvider.locale,
                supportedLocales: const [Locale('en'), Locale('ar')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // ── Routing: show login if not authenticated ──
                home: authProvider.isAuthenticated
                    ? const ShellScreen()
                    : const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}