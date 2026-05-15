import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/password_strength_meter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final email = ref.read(currentAuthUserProvider)?.email;
    if (email == null) {
      _showError('Session expirée. Reconnecte-toi.');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(authRepositoryProvider);

      // 1. Vérifier le mot de passe actuel en re-signant
      await repo.signIn(email: email, password: _currentCtrl.text);

      // 2. Mettre à jour vers le nouveau mot de passe
      await repo.updatePassword(_newCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mot de passe mis à jour'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) {
        _showError('Mot de passe actuel incorrect.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      appBar: AppBar(title: const Text('Changer le mot de passe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeInUp(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pour ta sécurité, on te demande ton mot de passe actuel avant de le remplacer.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    final base = Validators.password(v);
                    if (base != null) return base;
                    if (v == _currentCtrl.text) {
                      return 'Le nouveau doit être différent de l\'actuel';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                PasswordStrengthMeter(password: _newCtrl.text),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureNew,
                  decoration: const InputDecoration(
                    labelText: 'Confirmer le nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme';
                    if (v != _newCtrl.text) return 'Les mots de passe diffèrent';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Mettre à jour',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
