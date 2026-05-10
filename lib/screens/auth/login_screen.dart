// ─────────────────────────────────────────────
// lib/screens/auth/login_screen.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/shell_screen.dart';
import 'register_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure    = true;
  bool  _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs    = await SharedPreferences.getInstance();
    final email    = prefs.getString('saved_email') ?? '';
    final password = prefs.getString('saved_password') ?? '';
    if (email.isNotEmpty) {
      setState(() {
        _emailCtrl.text = email;
        _passCtrl.text  = password;
        _rememberMe     = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email',    _emailCtrl.text.trim());
      await prefs.setString('saved_password', _passCtrl.text);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) {
      await _saveCredentials();
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShellScreen(),
        transitionDuration: Duration.zero,
      ));
    }
  }

  void _goRegister() => Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, __, ___) => const RegisterScreen(),
    transitionDuration: Duration.zero,
  ));

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final auth   = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Toggle row — always LTR, never flips with locale ───────────
            Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dark mode — always LEFT
                    Consumer<ThemeProvider>(
                      builder: (_, tp, __) => IconButton(
                        icon: Icon(tp.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded),
                        tooltip: tp.isDark ? l10n.lightMode : l10n.darkMode,
                        onPressed: () =>
                            context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ),
                    // Language — always RIGHT
                    TextButton.icon(
                      onPressed: () => locale.setLocale(locale.isArabic
                          ? const Locale('en')
                          : const Locale('ar')),
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(locale.isArabic ? 'English' : 'العربية'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Centered content block: logo sits above fields naturally ───
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: MediaQuery.of(context).viewInsets.bottom > 0
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 150, // Available height minus toggle row
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Logo at top ──────────────────────────────────────
                            Center(
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  AppColors.primary, BlendMode.srcIn),
                                child: Image.asset(
                                  'assets/icons/saaf_logo2.png',
                                  width: 220, height: 220,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            // Pushes text forms up slightly
                            const Spacer(flex: 1),

                            // ── Email ────────────────────────────────────────────
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.email,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? l10n.emailInvalid
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // ── Password ─────────────────────────────────────────
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: l10n.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.isEmpty)
                                      ? l10n.passwordRequired
                                      : null,
                            ),

                            const SizedBox(height: 4),

                            // ── Remember Me + Forgot password ────────────────────
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                ),
                                Text(l10n.rememberMe,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(l10n.forgotPassword),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // ── Error ────────────────────────────────────────────
                            if (auth.errorKey != null)
                              _ErrorBanner(
                                message: _resolveError(l10n, auth.errorKey!),
                                onDismiss: () =>
                                    context.read<AuthProvider>().clearError(),
                              ),

                            const SizedBox(height: 16),

                            // ── Login button ─────────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ))
                                    : Text(l10n.login),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Go to register ───────────────────────────────────
                            TextButton(
                              onPressed: _goRegister,
                              child: Text(l10n.noAccount),
                            ),
                            
                            // More space at the bottom to push the forms up towards the center
                            const Spacer(flex: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveError(AppLocalizations l, String key) {
    switch (key) {
      case 'errorInvalidCredentials': return l.errorInvalidCredentials;
      case 'errorNetwork':            return l.errorNetwork;
      default:                        return l.errorGeneric;
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }
}