import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../providers/appointments_providers.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rendez-vous')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/appointments/add'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau RDV'),
      ),
      body: appointmentsAsync.when(
        loading: () => const LoadingPaw(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          final byDay = <DateTime, List<Appointment>>{};
          for (final a in list) {
            byDay.putIfAbsent(_dayKey(a.dateHeure), () => []).add(a);
          }
          final selected = _selectedDay ?? DateTime.now();
          final dayApts = byDay[_dayKey(selected)] ?? [];

          return Column(
            children: [
              _buildCalendar(byDay),
              const Divider(height: 1),
              Expanded(child: _buildDayList(dayApts, selected)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<Appointment>> byDay) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<Appointment>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _format,
          locale: 'fr_FR',
          startingDayOfWeek: StartingDayOfWeek.monday,
          eventLoader: (day) => byDay[_dayKey(day)] ?? const [],
          selectedDayPredicate: (d) =>
              _selectedDay != null && isSameDay(_selectedDay, d),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onFormatChanged: (f) => setState(() => _format = f),
          onPageChanged: (focused) => _focusedDay = focused,
          headerStyle: HeaderStyle(
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle:
                AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
            titleTextStyle: AppTextStyles.headlineMedium,
            leftChevronIcon: const Icon(Icons.chevron_left,
                color: AppColors.primaryDark),
            rightChevronIcon: const Icon(Icons.chevron_right,
                color: AppColors.primaryDark),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.secondaryDark,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            weekendTextStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.danger.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildDayList(List<Appointment> apts, DateTime day) {
    final dateLabel = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
    if (apts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 30),
          EmptyState(
            icon: Icons.event_available,
            title: 'Aucun RDV ce jour',
            subtitle: dateLabel,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: apts.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(dateLabel, style: AppTextStyles.headlineMedium),
          );
        }
        final a = apts[i - 1];
        return FadeInUp(
          delay: Duration(milliseconds: 60 * i),
          child: _AppointmentTile(appointment: a),
        );
      },
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  final Appointment appointment;
  const _AppointmentTile({required this.appointment});

  Color get _statusColor {
    switch (appointment.statut) {
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

  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, AppointmentStatus newStatus) async {
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateStatus(appointment.id, newStatus);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(upcomingAppointmentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Statut mis à jour : ${newStatus.label}'),
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

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context: context,
      title: 'Supprimer ce rendez-vous ?',
      message:
          '${appointment.motif ?? "Ce RDV"} du ${DateFormat('dd/MM/yyyy').format(appointment.dateHeure)} sera supprimé.',
      icon: Icons.delete_outline,
      isDestructive: true,
      confirmLabel: 'Supprimer',
    );
    if (ok != true) return;
    try {
      await ref.read(appointmentRepositoryProvider).delete(appointment.id);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(upcomingAppointmentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rendez-vous supprimé'),
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
    final timeFmt = DateFormat('HH:mm', 'fr_FR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeFmt.format(appointment.dateHeure),
                    style: AppTextStyles.headlineMedium.copyWith(
                        color: _statusColor, fontWeight: FontWeight.bold)),
                // Chip cliquable pour changer le statut
                GestureDetector(
                  onTap: () => _showStatusMenu(context, ref),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _statusColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(appointment.statut.label,
                            style: AppTextStyles.caption.copyWith(
                                color: _statusColor,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Icon(Icons.expand_more, size: 14, color: _statusColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.motif ?? 'Consultation',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (appointment.animalNom != null)
                    Row(
                      children: [
                        const Icon(Icons.pets,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(appointment.animalNom!,
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  if (appointment.veterinaireNom != null)
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('Dr ${appointment.veterinaireNom}',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                ],
              ),
            ),
            // Bouton supprimer
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 20),
              tooltip: 'Supprimer',
              onPressed: () => _delete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Changer le statut', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            ...AppointmentStatus.values.map((s) {
              final isSelected = s == appointment.statut;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
                title: Text(s.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
                onTap: () {
                  Navigator.pop(context);
                  if (!isSelected) _changeStatus(context, ref, s);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
