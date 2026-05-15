import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// Écran de vérification du code OTP à 6 chiffres reçu par email
/// après l'inscription.
class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;
  bool _resending = false;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendIn = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  String get _code => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saisis les 6 chiffres'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _verifying = true);
    try {
      await ref.read(authRepositoryProvider).verifySignUpOtp(
            email: widget.email,
            code: _code,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email confirmé — Bienvenue !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.go(AppRoutes.dashboard);
    } on AuthException catch (e) {
      _showError(_translate(e.message));
      _resetCode();
    } catch (_) {
      _showError('Erreur. Vérifie ta connexion.');
      _resetCode();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendSignUpOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nouveau code envoyé'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _startResendCountdown();
    } catch (e) {
      _showError('Impossible de renvoyer le code : $e');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _resetCode() {
    for (final c in _ctrls) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  String _translate(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('expired')) return 'Code expiré. Demande un nouveau code.';
    if (m.contains('invalid')) return 'Code incorrect. Vérifie et réessaie.';
    return msg;
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_unread,
                          size: 56, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Vérifie ton email',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Un code à 6 chiffres a été envoyé à\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: FadeInUp(
                child: Column(
                  children: [
                    _OtpInputs(
                      controllers: _ctrls,
                      focusNodes: _focusNodes,
                      onCompleted: _verify,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Vérifier',
                      icon: Icons.check_circle_outline,
                      loading: _verifying,
                      onPressed: _verifying ? null : _verify,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Pas reçu ? ',
                            style: AppTextStyles.bodyMedium),
                        if (_resendIn > 0)
                          Text('Réessaie dans ${_resendIn}s',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary))
                        else if (_resending)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          GestureDetector(
                            onTap: _resend,
                            child: Text(
                              'Renvoyer le code',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpInputs extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onCompleted;

  const _OtpInputs({
    required this.controllers,
    required this.focusNodes,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) => _box(context, i)),
    );
  }

  Widget _box(BuildContext context, int i) {
    return SizedBox(
      width: 46,
      child: TextField(
        controller: controllers[i],
        focusNode: focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        autofocus: i == 0,
        style: AppTextStyles.headlineLarge.copyWith(fontSize: 22),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryDark, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) {
            focusNodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            focusNodes[i - 1].requestFocus();
          }
          if (i == 5 && v.isNotEmpty) {
            final code = controllers.map((c) => c.text).join();
            if (code.length == 6) onCompleted();
          }
        },
      ),
    );
  }
}
