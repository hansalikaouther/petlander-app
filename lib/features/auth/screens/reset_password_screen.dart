import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/password_strength_meter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updatePassword(_newCtrl.text);
      repo.clearLastEvent();
      await repo.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe mis à jour. Connecte-toi avec ton nouveau mot de passe.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.go(AppRoutes.login);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : ${e.message}'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 32),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    ZoomIn(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset, size: 48, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nouveau mot de passe',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choisis un mot de passe sécurisé pour ton compte',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: FadeInUp(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _newCtrl,
                          obscureText: _obscure,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: Validators.password,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 8),
                        PasswordStrengthMeter(password: _newCtrl.text),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirme le mot de passe';
                            if (v != _newCtrl.text) return 'Les mots de passe ne correspondent pas';
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: 'Enregistrer le mot de passe',
                          icon: Icons.check,
                          loading: _saving,
                          onPressed: _saving ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
