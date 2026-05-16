import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../animals/providers/animals_providers.dart';
import '../providers/vaccinations_providers.dart';

class RecommendedVaccinesScreen extends ConsumerWidget {
  final String animalId;
  const RecommendedVaccinesScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalAsync = ref.watch(animalDetailProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccins recommandés')),
      body: animalAsync.when(
        loading: () => const LoadingPaw(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (animal) {
          final refsAsync = ref.watch(vaccinReferencesProvider(animal.type.dbValue));
          return refsAsync.when(
            loading: () => const LoadingPaw(),
            error: (e, _) => Center(child: Text('Erreur : $e')),
            data: (refs) {
              if (refs.isEmpty) {
                return const EmptyState(
                  icon: Icons.vaccines,
                  title: 'Aucune recommandation',
                  subtitle: 'Aucun vaccin spécifique pour ce type d\'animal',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: AppColors.accentDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Voici les vaccins recommandés pour ${animal.nom} (${animal.type.label}).',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...refs.asMap().entries.map((entry) => FadeInUp(
                        delay: Duration(milliseconds: 50 * entry.key),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.4),
                              child: const Icon(Icons.vaccines,
                                  color: AppColors.primaryDark),
                            ),
                            title: Text(entry.value.nomVaccin,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600)),
                            subtitle: entry.value.dureeValiditeMois != null
                                ? Text(
                                    'Validité : ${entry.value.dureeValiditeMois} mois')
                                : null,
                            trailing: const Icon(Icons.add_circle_outline,
                                color: AppColors.primaryDark),
                            onTap: () {
                              context.push(
                                '${AppRoutes.animalDetail(animalId)}/vaccinations/add',
                                extra: entry.value.id,
                              );
                            },
                          ),
                        ),
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
