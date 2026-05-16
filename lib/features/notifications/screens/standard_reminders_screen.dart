import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/standard_reminders.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../animals/providers/animals_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../../shared/models/notification_item.dart';
import 'package:intl/intl.dart';

class StandardRemindersScreen extends ConsumerStatefulWidget {
  const StandardRemindersScreen({super.key});

  @override
  ConsumerState<StandardRemindersScreen> createState() =>
      _StandardRemindersScreenState();
}

class _StandardRemindersScreenState
    extends ConsumerState<StandardRemindersScreen> {
  Animal? _selectedAnimal;

  // ── Rappel personnalisé ────────────────────────────────────────────────────
  static const _suggestions = [
    'Vaccination',
    'Consultation vétérinaire',
    'Toilettage',
    'Traitement antiparasitaire',
    'Vermifuge',
    'Contrôle de poids',
    'Renouvellement d\'ordonnance',
    'Stérilisation',
    'Bilan de santé annuel',
    'Nettoyage des oreilles',
    'Soin dentaire',
    'Autre...',
  ];

  String? _selectedSuggestion;
  final _customTitleCtrl = TextEditingController();
  DateTime? _customDate;
  bool _schedulingCustom = false;

  @override
  void dispose() {
    _customTitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animalsAsync = ref.watch(animalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels')),
      body: animalsAsync.when(
        loading: () => const LoadingPaw(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (animals) {
          if (animals.isEmpty) {
            return const EmptyState(
              icon: Icons.pets,
              title: 'Aucun animal',
              subtitle: 'Ajoute d\'abord un animal pour activer des rappels',
            );
          }
          _selectedAnimal ??= animals.first;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Bannière web ─────────────────────────────────────────────
              if (kIsWeb)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Les notifications locales ne fonctionnent pas sur navigateur. Installe l\'app Android.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Sélecteur animal ─────────────────────────────────────────
              DropdownButtonFormField<Animal>(
                initialValue: _selectedAnimal,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pour quel animal ?',
                  prefixIcon: Icon(Icons.pets),
                ),
                items: animals
                    .map((a) =>
                        DropdownMenuItem(value: a, child: Text(a.nom)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAnimal = v),
              ),
              const SizedBox(height: 24),

              // ── Section rappel personnalisé ───────────────────────────────
              FadeInUp(
                child: _SectionTitle(
                  icon: Icons.add_alarm_outlined,
                  label: 'Rappel personnalisé',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                delay: const Duration(milliseconds: 60),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedSuggestion),
                          initialValue: _selectedSuggestion,
                          decoration: const InputDecoration(
                            labelText: 'Type de rappel *',
                            prefixIcon: Icon(Icons.list_outlined),
                          ),
                          hint: const Text('Choisir un type'),
                          items: _suggestions
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedSuggestion = v),
                        ),
                        if (_selectedSuggestion == 'Autre...') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Préciser *',
                              prefixIcon: Icon(Icons.edit_note_outlined),
                              hintText: 'Ex : Vaccin antirabique spécifique…',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickCustomDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de l\'événement *',
                              prefixIcon:
                                  Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              _customDate == null
                                  ? 'Choisir une date'
                                  : '${_customDate!.day}/${_customDate!.month}/${_customDate!.year}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _customDate == null
                                    ? AppColors.textSecondary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Une notification sera envoyée 24 h avant la date choisie.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.info),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _schedulingCustom
                              ? null
                              : _scheduleCustomReminder,
                          icon: _schedulingCustom
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.notifications_active_outlined),
                          label: const Text('Programmer le rappel'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Section rappels standards ─────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _SectionTitle(
                  icon: Icons.repeat_outlined,
                  label: 'Rappels standards',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Active des rappels récurrents pour ne rien oublier.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              ...StandardReminders.all.asMap().entries.map((entry) {
                return FadeInUp(
                  delay: Duration(milliseconds: 120 + 60 * entry.key),
                  child: _ReminderCard(
                    reminder: entry.value,
                    onActivate: () => _activateStandard(entry.value),
                  ),
                );
              }),

              const SizedBox(height: 28),

              // ── Section : Mes rappels programmes ─────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _SectionTitle(
                  icon: Icons.event_available_outlined,
                  label: 'Mes rappels programmés',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 10),
              _buildSavedRemindersList(),
            ],
          );
        },
      ),
    );
  }

  // ── Liste des rappels programmes (Supabase) ─────────────────────────────
  Widget _buildSavedRemindersList() {
    final remindersAsync = ref.watch(remindersProvider);
    return remindersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Erreur : $e',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger)),
      data: (reminders) {
        if (reminders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Aucun rappel programmé. Cree-en un ci-dessus !',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: reminders
              .map((r) => _SavedReminderCard(
                    item: r,
                    onDelete: () => _deleteReminder(r),
                  ))
              .toList(),
        );
      },
    );
  }

  Future<void> _deleteReminder(NotificationItem item) async {
    try {
      await NotificationsRepository().delete(item.id);
      ref.invalidate(remindersProvider);
      ref.invalidate(notificationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rappel supprimé'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Sélecteur de date pour rappel perso ───────────────────────────────────
  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Date de l\'événement',
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _customDate = picked);
  }

  // ── Programmer le rappel personnalisé ─────────────────────────────────────
  Future<void> _scheduleCustomReminder() async {
    // Résolution du titre depuis le dropdown ou le champ "Autre..."
    final String title;
    if (_selectedSuggestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez choisir un type de rappel'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    } else if (_selectedSuggestion == 'Autre...') {
      final custom = _customTitleCtrl.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez préciser le titre du rappel'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      title = custom;
    } else {
      title = _selectedSuggestion!;
    }
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez saisir un titre pour le rappel'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_customDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez choisir une date'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _schedulingCustom = true);
    try {
      await NotificationService.requestPermissions();
      if (!mounted) return;

      final animalNom = _selectedAnimal?.nom ?? '';
      // Notification 24 h avant l'événement à 9h
      final eventAt = DateTime(
          _customDate!.year, _customDate!.month, _customDate!.day, 9, 0);
      final notifAt = eventAt.subtract(const Duration(hours: 24));

      if (notifAt.isBefore(DateTime.now())) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'La date choisie est trop proche — le rappel serait dans le passé.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final notifTitle = animalNom.isNotEmpty
          ? '$title — $animalNom'
          : title;
      final notifBody =
          'Rappel : "$title" est prévu demain${animalNom.isNotEmpty ? ' pour $animalNom' : ''}.';

      await NotificationService.schedule(
        id: '$title-${_customDate.toString()}'.hashCode,
        title: notifTitle,
        body: notifBody,
        scheduledAt: notifAt,
      );

      // Enregistre dans le centre de notifications Supabase
      final user = ref.read(currentAuthUserProvider);
      if (user != null) {
        await NotificationsRepository().create(
          userId: user.id,
          titre: notifTitle,
          contenu: notifBody,
          type: 'rappel_perso',
        );
        ref.invalidate(remindersProvider);
        ref.invalidate(notificationsProvider);
      }

      if (!mounted) return;
      final d = _customDate!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Rappel programmé pour le ${d.day}/${d.month}/${d.year} à 9h00 '
            '(notification 24 h avant)'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));

      // Réinitialise le formulaire
      _customTitleCtrl.clear();
      setState(() {
        _customDate = null;
        _selectedSuggestion = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _schedulingCustom = false);
    }
  }

  // ── Activer un rappel standard ────────────────────────────────────────────
  Future<void> _activateStandard(StandardReminder r) async {
    if (_selectedAnimal == null) return;

    await NotificationService.requestPermissions();
    if (!mounted) return;

    final defaultDate = DateTime.now().add(Duration(days: r.recurrenceDays));
    final picked = await showDatePicker(
      context: context,
      initialDate: defaultDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Date du premier rappel',
      locale: const Locale('fr', 'FR'),
    );
    if (picked == null || !mounted) return;

    final scheduledAt =
        DateTime(picked.year, picked.month, picked.day, 9, 0);
    try {
      await NotificationService.schedule(
        id: '${r.type}-${_selectedAnimal!.id}'.hashCode,
        title: '${r.label} — ${_selectedAnimal!.nom}',
        body: r.message,
        scheduledAt: scheduledAt,
      );

      // Enregistre dans le centre de notifications Supabase
      final user = ref.read(currentAuthUserProvider);
      if (user != null) {
        try {
          await NotificationsRepository().create(
            userId: user.id,
            titre: '${r.label} — ${_selectedAnimal!.nom}',
            contenu: r.message,
            type: 'rappel_standard',
          );
          ref.invalidate(remindersProvider);
          ref.invalidate(notificationsProvider);
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Rappel programmé le ${picked.day}/${picked.month}/${picked.year} à 9h00'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: AppTextStyles.headlineMedium
                .copyWith(fontSize: 16, color: color)),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final StandardReminder reminder;
  final VoidCallback onActivate;
  const _ReminderCard({required this.reminder, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(reminder.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text('Tous les ${reminder.recurrenceDays} jours',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            FilledButton(
              onPressed: onActivate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Activer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte affichant un rappel deja programme (depuis Supabase).
class _SavedReminderCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onDelete;
  const _SavedReminderCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPerso = item.type == 'rappel_perso';
    final color = isPerso ? AppColors.accent : AppColors.primary;
    final dateStr = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(item.dateEnvoi);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPerso ? Icons.notifications_active : Icons.repeat,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.titre,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (item.contenu != null && item.contenu!.isNotEmpty)
                    Text(
                      item.contenu!,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'Programmé le $dateStr',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
