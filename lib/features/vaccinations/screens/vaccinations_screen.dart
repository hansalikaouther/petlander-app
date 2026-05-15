import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/vaccination.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../providers/vaccinations_providers.dart';

class VaccinationsScreen extends ConsumerWidget {
  final String animalId;
  const VaccinationsScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinationsAsync = ref.watch(vaccinationsByAnimalProvider(animalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/animals/$animalId/vaccinations/add'),
        icon: const Icon(Icons.add),
        label: const Text('Vaccin'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(vaccinationsByAnimalProvider(animalId)),
        child: vaccinationsAsync.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.vaccines,
                title: 'Aucune vaccination',
                subtitle: 'Ajoute le premier vaccin de ton animal',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: list.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 60 * i),
                child: _VaccinationTimelineItem(
                  vaccination: list[i],
                  isFirst: i == 0,
                  isLast: i == list.length - 1,
                  animalId: animalId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VaccinationTimelineItem extends ConsumerWidget {
  final Vaccination vaccination;
  final bool isFirst;
  final bool isLast;
  final String animalId;
  const _VaccinationTimelineItem({
    required this.vaccination,
    required this.isFirst,
    required this.isLast,
    required this.animalId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Supprimer cette vaccination ?',
      message: '"${vaccination.nomVaccin ?? 'Vaccin'}" sera retiré de l\'historique.',
      icon: Icons.delete_outline,
      isDestructive: true,
      confirmLabel: 'Supprimer',
    );
    if (ok != true) return;
    try {
      await ref.read(vaccinationRepositoryProvider).delete(vaccination.id);
      ref.invalidate(vaccinationsByAnimalProvider(animalId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vaccination supprimée'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Color _statusColor() {
    switch (vaccination.status) {
      case VaccinationStatus.upToDate:
        return AppColors.success;
      case VaccinationStatus.soon:
        return AppColors.warning;
      case VaccinationStatus.overdue:
        return AppColors.danger;
      case VaccinationStatus.unknown:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel() {
    switch (vaccination.status) {
      case VaccinationStatus.upToDate:
        return 'À jour';
      case VaccinationStatus.soon:
        return 'Bientôt';
      case VaccinationStatus.overdue:
        return 'Dépassé';
      case VaccinationStatus.unknown:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    final color = _statusColor();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          SizedBox(
            width: 50,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vaccination.nomVaccin ?? 'Vaccin',
                              style: AppTextStyles.headlineMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(),
                              style: AppTextStyles.caption
                                  .copyWith(color: color, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger, size: 20),
                            tooltip: 'Supprimer',
                            onPressed: () => _confirmDelete(context, ref),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Effectué : ${dateFmt.format(vaccination.dateVaccination)}',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                      if (vaccination.dateRappel != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.notifications_active_outlined,
                                size: 14, color: color),
                            const SizedBox(width: 4),
                            Text('Rappel : ${dateFmt.format(vaccination.dateRappel!)}',
                                style: AppTextStyles.bodySmall.copyWith(color: color)),
                          ],
                        ),
                      ],
                      if (vaccination.lotVaccin != null) ...[
                        const SizedBox(height: 4),
                        Text('Lot : ${vaccination.lotVaccin}',
                            style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
