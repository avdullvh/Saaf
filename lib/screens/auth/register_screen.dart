// ─────────────────────────────────────────────
// lib/screens/auth/register_screen.dart
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/shell_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool  _obscure     = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      fullName: _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ShellScreen(),
          transitionDuration: Duration.zero,
        ),
        (_) => false,
      );
    }
  }

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

                            // ── Full name ────────────────────────────────────────
                            TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.fullName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? l10n.fullNameRequired
                                      : null,
                            ),

                            const SizedBox(height: 16),

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
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return l10n.passwordRequirements;
                                }
                                final hasLetter =
                                    RegExp(r'[A-Za-z]').hasMatch(v);
                                final hasNumber = RegExp(r'\d').hasMatch(v);
                                if (!hasLetter || !hasNumber) {
                                  return l10n.passwordRequirements;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // ── Confirm password ─────────────────────────────────
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: l10n.confirmPassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (v) =>
                                  v != _passCtrl.text
                                      ? l10n.passwordsDoNotMatch
                                      : null,
                            ),

                            const SizedBox(height: 16),

                            // ── Error ────────────────────────────────────────────
                            if (auth.errorKey != null)
                              _ErrorBanner(
                                message: auth.errorKey == 'errorNetwork'
                                    ? l10n.errorNetwork
                                    : l10n.errorGeneric,
                                onDismiss: () =>
                                    context.read<AuthProvider>().clearError(),
                              ),

                            const SizedBox(height: 16),

                            // ── Register button ──────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white))
                                    : Text(l10n.register),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Back to login ────────────────────────────────────
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.hasAccount),
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