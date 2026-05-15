import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../shared/widgets/app_logo.dart';
import '../providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectAfterDelay());
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _redirectAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final repo = ref.read(authRepositoryProvider);
    if (repo.isRecoverySession ||
        repo.lastEvent == AuthChangeEvent.passwordRecovery) {
      context.go(AppRoutes.resetPassword);
      return;
    }
    // Sign out any existing session so every cold start begins at login.
    if (repo.currentAuthUser != null) {
      await repo.signOut();
    }
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Pattes décoratives qui flottent en arrière-plan
            ..._floatingPaws(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: const Duration(milliseconds: 700),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                        CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.45),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 160),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Petlander',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'Track, Care And Love',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  Pulse(
                    infinite: true,
                    duration: const Duration(milliseconds: 1300),
                    child: const Icon(Icons.pets, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _floatingPaws() {
    return [
      _floatingPaw(top: 60, left: 30, size: 28, delay: 200),
      _floatingPaw(top: 120, right: 40, size: 36, delay: 400),
      _floatingPaw(bottom: 100, left: 50, size: 32, delay: 600),
      _floatingPaw(bottom: 180, right: 60, size: 24, delay: 800),
    ];
  }

  Widget _floatingPaw({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required int delay,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: FadeIn(
        delay: Duration(milliseconds: delay),
        child: Pulse(
          infinite: true,
          duration: const Duration(milliseconds: 2400),
          child: Icon(
            Icons.pets,
            size: size,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
