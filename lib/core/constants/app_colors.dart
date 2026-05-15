import 'package:flutter/material.dart';

/// Palette Stitch dark — Petlander.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C3AED);      // violet Stitch
  static const Color secondary = Color(0xFFF97316);    // orange CTA
  static const Color accent = Color(0xFFEC4899);       // rose accent

  static const Color primaryDark = Color(0xFF6D28D9);  // violet profond
  static const Color secondaryDark = Color(0xFFEA6C0E);
  static const Color accentDark = Color(0xFFDB2777);

  // Fonds (dark-first)
  static const Color background = Color(0xFF09091F);
  static const Color surface = Color(0xFF141433);
  static const Color cardBackground = Color(0xFF1C1C3E);

  // Texte
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // États
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);

  // Dark aliases (kept for compat)
  static const Color darkBackground = Color(0xFF09091F);
  static const Color darkSurface = Color(0xFF141433);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
  );

  // Rose → orange (cartes animaux style REX)
  static const LinearGradient petGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E8C), Color(0xFFF97316)],
  );

  // Violet → rose (cartes animaux style ELSA)
  static const LinearGradient petGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C2BD9), Color(0xFFEC4899)],
  );

  // Violet → bleu (variation)
  static const LinearGradient petGradient3 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF09091F), Color(0xFF141433)],
  );

  static List<LinearGradient> get petGradients =>
      [petGradient1, petGradient2, petGradient3];

  // ── Couleurs pastel par type animal ────────────────────────────────────────
  static const Color animalChien   = Color(0xFF7EB5E0); // bleu ciel
  static const Color animalChat    = Color(0xFFF4A7B9); // rose poudré
  static const Color animalLapin   = Color(0xFFB8A0D8); // lavande
  static const Color animalOiseau  = Color(0xFFFFCC6A); // jaune pêche
  static const Color animalRongeur = Color(0xFFFFAA70); // orange pêche
  static const Color animalReptile = Color(0xFF7FCBB0); // menthe verte
  static const Color animalAutre   = Color(0xFF90B0D0); // bleu acier

  // Gradients pastels pour les cartes animaux (fond haut de carte)
  static const LinearGradient gradientChien = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFD0ECFF), Color(0xFF7EB5E0)],
  );
  static const LinearGradient gradientChat = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFFDDE6), Color(0xFFF4A7B9)],
  );
  static const LinearGradient gradientLapin = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE6DEFF), Color(0xFFB8A0D8)],
  );
  static const LinearGradient gradientOiseau = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3CC), Color(0xFFFFCC6A)],
  );
  static const LinearGradient gradientRongeur = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFFE5CC), Color(0xFFFFAA70)],
  );
  static const LinearGradient gradientReptile = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFCCF0E4), Color(0xFF7FCBB0)],
  );
  static const LinearGradient gradientAutre = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFD8EAF8), Color(0xFF90B0D0)],
  );
}
