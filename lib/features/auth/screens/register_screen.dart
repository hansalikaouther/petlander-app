import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/password_strength_meter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _adresseCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      debugPrint('[Register] signUp pour ${_emailCtrl.text.trim()}');
      final res = await ref.read(authRepositoryProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            nom: _nomCtrl.text.trim(),
            numeroTelephone: _phoneCtrl.text.trim(),
            adresse: _adresseCtrl.text.trim(),
          );
      debugPrint('[Register] signUp OK : session=${res.session != null}, user=${res.user?.id}');
      if (!mounted) return;
      if (res.session != null) {
        // Email auto-confirmé : on redirige vers le dashboard
        _showSuccess('Compte créé ! Bienvenue.');
        context.go(AppRoutes.dashboard);
      } else {
        // Email à confirmer : redirection vers l'écran de vérification OTP
        _showSuccess('Compte créé ! Saisis le code reçu par email.');
        context.go(
          AppRoutes.verifyOtp,
          extra: {'email': _emailCtrl.text.trim()},
        );
      }
    } on AuthException catch (e) {
      debugPrint('[Register] AuthException : code=${e.statusCode} message="${e.message}"');
      // On affiche le message Supabase BRUT + notre traduction si dispo
      final translated = _translateAuthError(e.message);
      final hint = translated == e.message ? '' : '\n($translated)';
      _showError('Supabase : ${e.message}$hint');
    } catch (e, stack) {
      debugPrint('[Register] Erreur inattendue : $e\n$stack');
      _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('user already registered') ||
        m.contains('already exists')) {
      return 'Un compte existe déjà avec cet email. Utilise "Mot de passe oublié" pour te connecter.';
    }
    if (m.contains('password should be at least')) {
      return 'Mot de passe trop court (min. 8 caractères avec maj + min + chiffre).';
    }
    if (m.contains('weak password') || m.contains('password')) {
      return 'Mot de passe trop faible. Utilise une maj + min + chiffre.';
    }
    if (m.contains('invalid email') || m.contains('email')) {
      return 'Adresse email invalide.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Trop de tentatives. Attends quelques minutes (limite Supabase 4 emails/h).';
    }
    if (m.contains('network') || m.contains('failed host')) {
      return 'Pas de connexion internet ou serveur Supabase injoignable.';
    }
    return message;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 6),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
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
                    child: const Icon(Icons.pets, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('Bienvenue chez Petlander',
                      style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Crée ton compte pour suivre tes compagnons',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: FadeInUp(child: _buildForm()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'ex : Hansali Kaouter',
            ),
            validator: (v) => Validators.name(v, label: 'Le nom'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone (optionnel)',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'ex : 05 12 34 56 78',
            ),
            validator: Validators.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _adresseCtrl,
            decoration: const InputDecoration(
              labelText: 'Adresse (optionnel)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          PasswordStrengthMeter(password: _passwordCtrl.text),
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
              if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
              return null;
            },
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Créer mon compte',
            icon: Icons.pets,
            loading: _loading,
            onPressed: _loading ? null : _submit,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Déjà un compte ? ', style: AppTextStyles.bodyMedium),
              GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: Text(
                  'Se connecter',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
