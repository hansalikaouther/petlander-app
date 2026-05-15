import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          BounceInDown(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const AppLogo(size: 90),
                  const SizedBox(height: 12),
                  Text('Petlander',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: Colors.white, fontSize: 28)),
                  const SizedBox(height: 4),
                  const Text('Track, Care And Love',
                      style: TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Version 1.0.0',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _section(
              context,
              icon: Icons.school_outlined,
              title: 'Projet de Fin d\'Études',
              body:
                  'Petlander est une application mobile multiplateforme développée '
                  'comme Projet de Fin d\'Études (Master Informatique).\n\n'
                  'Elle a pour objectif d\'offrir aux propriétaires d\'animaux '
                  'domestiques un carnet de santé numérique complet, intuitif '
                  'et accessible à tout moment.',
            ),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _section(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Fonctionnalités principales',
              body:
                  '• Gestion multi-animaux (chien, chat, lapin, oiseau...)\n'
                  '• Vaccinations et rappels automatiques (J-7)\n'
                  '• Consultations, traitements, examens, opérations\n'
                  '• Suivi de croissance avec graphiques\n'
                  '• Allergies & maladies chroniques\n'
                  '• Documents médicaux et ordonnances\n'
                  '• Rendez-vous + calendrier\n'
                  '• Notifications locales\n'
                  '• Export PDF du carnet de santé\n'
                  '• Mode sombre',
            ),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: _section(
              context,
              icon: Icons.code,
              title: 'Stack technique',
              body: '• Flutter 3.x (Dart) — Multi-plateforme\n'
                  '• Supabase — PostgreSQL + Auth + Storage\n'
                  '• Riverpod — Gestion d\'état\n'
                  '• GoRouter — Navigation déclarative\n'
                  '• fl_chart — Graphiques de croissance\n'
                  '• Notifications locales planifiées',
            ),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: _section(
              context,
              icon: Icons.favorite,
              title: 'Crédits',
              body: 'Conception, design et développement :\n'
                  'Kaouther Hansali\n\n'
                  'Encadrante : OUGOUTI Naima Souad\n\n'
                  '© 2026 Petlander. Tous droits réservés.',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(BuildContext context,
      {required IconData icon,
      required String title,
      required String body}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  child: Icon(icon, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.headlineMedium
                          .copyWith(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
