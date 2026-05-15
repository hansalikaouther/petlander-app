import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/consultation.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../appointments/providers/appointments_providers.dart';
import '../providers/consultations_providers.dart';

class ConsultationsScreen extends ConsumerWidget {
  final String animalId;
  const ConsultationsScreen({super.key, required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultAsync = ref.watch(consultationsByAnimalProvider(animalId));
    final rdvAsync = ref.watch(appointmentsByAnimalProvider(animalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Consultations & RDV')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/animals/$animalId/consultations/add'),
        icon: const Icon(Icons.add),
        label: const Text('Consultation'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(consultationsByAnimalProvider(animalId));
          ref.invalidate(appointmentsByAnimalProvider(animalId));
        },
        child: consultAsync.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (consultations) {
            final rdvs = rdvAsync.valueOrNull ?? [];
            final upcomingRdvs =
                rdvs.where((r) => r.isUpcoming).toList();

            if (consultations.isEmpty && upcomingRdvs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.medical_services_outlined,
                    title: 'Aucune consultation',
                    subtitle: 'Enregistre la première visite vétérinaire',
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ─── Section RDV à venir ───
                if (upcomingRdvs.isNotEmpty) ...[
                  _sectionTitle('Rendez-vous à venir',
                      Icons.event_outlined, AppColors.warning),
                  const SizedBox(height: 8),
                  ...upcomingRdvs.asMap().entries.map(
                        (e) => FadeInUp(
                          delay: Duration(milliseconds: 50 * e.key),
                          child: _RdvCard(
                            rdv: e.value,
                            animalId: animalId,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                ],
                // ─── Section Consultations passées ───
                if (consultations.isNotEmpty) ...[
                  _sectionTitle('Consultations',
                      Icons.medical_services_outlined, AppColors.primaryDark),
                  const SizedBox(height: 8),
                  ...consultations.asMap().entries.map(
                        (e) => FadeInUp(
                          delay: Duration(milliseconds: 50 * e.key),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConsultationCard(
                              consultation: e.value,
                              animalId: animalId,
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.headlineMedium.copyWith(color: color)),
      ],
    );
  }
}

class _RdvCard extends ConsumerWidget {
  final Appointment rdv;
  final String animalId;
  const _RdvCard({required this.rdv, required this.animalId});

  Color get _statusColor {
    switch (rdv.statut) {
      case AppointmentStatus.confirme:
        return AppColors.success;
      case AppointmentStatus.planifie:
        return AppColors.warning;
      case AppointmentStatus.passe:
        return AppColors.textSecondary;
      case AppointmentStatus.annule:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');
    return Card(
      color: AppColors.warning.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.3),
          child: const Icon(Icons.event, color: AppColors.warning),
        ),
        title: Text(rdv.motif ?? 'Rendez-vous',
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFmt.format(rdv.dateHeure),
                style: AppTextStyles.caption),
            if (rdv.veterinaireNom != null)
              Text('Dr ${rdv.veterinaireNom}', style: AppTextStyles.caption),
          ],
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(rdv.statut.label,
              style: AppTextStyles.caption.copyWith(
                  color: _statusColor, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _ConsultationCard extends ConsumerWidget {
  final Consultation consultation;
  final String animalId;
  const _ConsultationCard(
      {required this.consultation, required this.animalId});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Supprimer cette consultation ?',
      message:
          'La consultation du ${DateFormat('dd MMM yyyy', 'fr_FR').format(consultation.dateConsultation)} et ses traitements/examens liés seront supprimés.',
      icon: Icons.delete_outline,
      isDestructive: true,
      confirmLabel: 'Supprimer',
    );
    if (ok != true) return;
    try {
      await ref
          .read(consultationRepositoryProvider)
          .delete(consultation.id);
      ref.invalidate(consultationsByAnimalProvider(animalId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Consultation supprimée'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context
            .push('/animals/$animalId/consultations/${consultation.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.3),
                    child: const Icon(Icons.medical_services_outlined,
                        color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(consultation.motif ?? 'Consultation',
                            style: AppTextStyles.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(dateFmt.format(consultation.dateConsultation),
                            style: AppTextStyles.bodySmall),
                      ],
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
              if (consultation.diagnostic != null) ...[
                const SizedBox(height: 8),
                Text(consultation.diagnostic!,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  if (consultation.veterinaireNom != null)
                    _chip(Icons.person_outline,
                        'Dr ${consultation.veterinaireNom}'),
                  if (consultation.poids != null)
                    _chip(Icons.monitor_weight_outlined,
                        '${consultation.poids!.toStringAsFixed(1)} kg'),
                  if (consultation.temperature != null)
                    _chip(Icons.thermostat,
                        '${consultation.temperature!.toStringAsFixed(1)}°C'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption),
      ],
    );
  }
}
