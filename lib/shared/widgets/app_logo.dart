import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Affiche le logo Petlander si présent dans `assets/icons/petlander_logo.png`,
/// sinon retombe sur l'icône Material `pets` (gradient pastel).
class AppLogo extends StatelessWidget {
  final double size;
  final bool circular;

  const AppLogo({super.key, this.size = 96, this.circular = true});

  static const String _assetPath = 'assets/icons/petlander_logo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );

    if (!circular) return image;

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFFDF6F0),
        child: image,
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Icon(Icons.pets, size: size * 0.55, color: Colors.white),
    );
  }
}
