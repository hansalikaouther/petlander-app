import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Styles de texte — sans couleur fixe : le thème Material gère onSurface
/// (noir en mode jour, blanc en mode nuit) automatiquement.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, // gris — lisible sur fond clair ET sombre
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary, // toujours blanc sur bouton coloré
    letterSpacing: 0.5,
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, // gris — lisible sur fond clair ET sombre
  );
}
