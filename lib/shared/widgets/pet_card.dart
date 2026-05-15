import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../models/animal.dart';
import 'animal_icon.dart';

/// Card animal — gradient pastel en haut + info en bas.
class PetCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  final double? width;

  const PetCard({
    super.key,
    required this.animal,
    this.onTap,
    this.width,
  });

  // Gradient pastel différent par type animal
  LinearGradient _gradientFor(AnimalType type) {
    switch (type) {
      case AnimalType.chien:   return AppColors.gradientChien;
      case AnimalType.chat:    return AppColors.gradientChat;
      case AnimalType.lapin:   return AppColors.gradientLapin;
      case AnimalType.oiseau:  return AppColors.gradientOiseau;
      case AnimalType.rongeur: return AppColors.gradientRongeur;
      case AnimalType.reptile: return AppColors.gradientReptile;
      case AnimalType.autre:   return AppColors.gradientAutre;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(animal.type);
    final cardColor = gradient.colors.first;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Zone image / gradient (haut) ───────────────────────────────
              Expanded(
                flex: 6,
                child: animal.photoUrl != null && animal.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: animal.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _GradientTop(
                          gradient: gradient,
                          type: animal.type,
                        ),
                        errorWidget: (_, _, _) => _GradientTop(
                          gradient: gradient,
                          type: animal.type,
                        ),
                      )
                    : _GradientTop(gradient: gradient, type: animal.type),
              ),

              // ── Zone info (bas) ─────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Container(
                  color: cardColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      AnimalIcon(
                        type: animal.type,
                        size: 36,
                        animated: false,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              animal.nom,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              [
                                animal.type.label,
                                if (animal.race != null && animal.race!.isNotEmpty)
                                  animal.race!,
                              ].join(' • '),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _GradientTop extends StatelessWidget {
  final LinearGradient gradient;
  final AnimalType type;
  const _GradientTop({required this.gradient, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: BounceInDown(
          duration: const Duration(milliseconds: 700),
          child: AnimalIcon(
            type: type,
            size: 72,
            showBackground: false,
            animated: false,
          ),
        ),
      ),
    );
  }
}
