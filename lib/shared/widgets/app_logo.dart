import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Logo de l'app : cercle avec gradient pastel + patte blanche au centre.
/// Utilisé sur le splash screen et certains écrans d'accueil.
class AppLogo extends StatelessWidget {
  final double size;
  // ignore: unused_element_parameter
  final bool circular;

  const AppLogo({super.key, this.size = 96, this.circular = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Icon(Icons.pets, size: size * 0.55, color: Colors.white),
    );
  }
}
