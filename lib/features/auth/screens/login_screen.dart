import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } on AuthException catch (e) {
      _showError(_translateAuthError(e.message));
    } catch (_) {
      _showError('Une erreur est survenue. Réessaye.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login')) return 'Email ou mot de passe incorrect.';
    if (m.contains('email not confirmed')) {
      return 'Email non confirmé. Vérifie ta boîte mail.';
    }
    if (m.contains('network')) return 'Pas de connexion internet.';
    return message;
  }

  void _openForgotPasswordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ForgotPasswordSheet(initialEmail: _emailCtrl.text.trim()),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),
                // Logo + titre
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.pets,
                            size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Petlander',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bon retour !',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Formulaire
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPasswordSheet,
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bouton connexion avec gradient
                        _GradientButton(
                          label: 'Se connecter',
                          loading: _loading,
                          onPressed: _loading ? null : _submit,
                        ),
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Pas encore de compte ? ',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.register),
                              child: Text(
                                'Inscris-toi',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.4),
                    AppColors.accent.withValues(alpha: 0.4),
                  ],
                )
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (onPressed != null)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Bottom sheet mot de passe oublié ──────────────────────────────────────────
class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({this.initialEmail = ''});

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState
    extends ConsumerState<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.initialEmail);
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : ${e.message}'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur réseau. Réessaye.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _sent ? Icons.mark_email_read : Icons.lock_reset,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _sent ? 'Email envoyé !' : 'Mot de passe oublié',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _sent
                  ? 'Vérifie ta boîte de réception (et les spams). Clique sur le lien pour définir un nouveau mot de passe.'
                  : 'Saisis ton email. Tu recevras un lien pour réinitialiser ton mot de passe.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (!_sent) ...[
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: Validators.email,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _send(),
              ),
              const SizedBox(height: 16),
              _GradientButton(
                label: 'Envoyer le lien',
                loading: _sending,
                onPressed: _sending ? null : _send,
              ),
            ] else ...[
              _GradientButton(
                label: 'Fermer',
                loading: false,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
