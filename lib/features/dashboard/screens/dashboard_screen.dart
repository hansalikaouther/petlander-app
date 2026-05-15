import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/app_router.dart';
import '../../../shared/models/animal.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../../shared/widgets/pet_card.dart';
import '../../animals/providers/animals_providers.dart';
import '../../appointments/providers/appointments_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../daily_tips/data/daily_tip_service.dart';
import '../../daily_tips/data/daily_tips_database.dart';
import '../../daily_tips/widgets/daily_tip_dialog.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/providers/notifications_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _tipChecked = false;

  Future<void> _maybeShowDailyTip(List<Animal> animals) async {
    if (_tipChecked) return;
    _tipChecked = true;

    // Re-planifier le rappel local dans 10 jours
    await DailyTipService.scheduleReminderIn10Days();

    final types = animals.map((a) => a.type).toSet().toList();
    // Conseil différent à chaque démarrage
    final tip = DailyTipsDatabase.tipForLaunch(types);
    if (tip == null || !mounted) return;

    // Léger délai pour laisser l'UI se rendre avant le dialog
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await DailyTipDialog.show(context, tip);

    // Enregistre dans le centre de notifications (une fois par jour)
    final user = ref.read(currentAuthUserProvider);
    if (user != null) {
      try {
        final alreadyInserted =
            await DailyTipService.notifAlreadyInsertedToday();
        if (!alreadyInserted) {
          await NotificationsRepository().create(
            userId: user.id,
            titre: tip.title,
            contenu: tip.body.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1'),
            type: 'conseil',
          );
          await DailyTipService.markNotifInserted();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final animals = ref.watch(animalsProvider);
    final upcoming = ref.watch(upcomingAppointmentsProvider);

    // Déclenche le pop-up dès que la liste des animaux est chargée.
    animals.whenData((list) => _maybeShowDailyTip(list));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(animalsProvider);
            ref.invalidate(currentProfileProvider);
            ref.invalidate(upcomingAppointmentsProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _Header(userName: profile.valueOrNull?.nom),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _SearchBar(),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _StatsRow(animals: animals, upcoming: upcoming),
              ),
              const SizedBox(height: 24),
              _AnimalsSection(animals: animals),
              const SizedBox(height: 28),
              _QuickActionsGrid(),
              const SizedBox(height: 28),
              _UpcomingAppointments(upcoming: upcoming),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String? userName;
  const _Header({this.userName});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return 'Bonne nuit';
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;
    final initial = (userName?.isNotEmpty ?? false)
        ? userName!.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.55),
            AppColors.secondary.withValues(alpha: 0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'user_avatar',
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  initial,
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
                Text(
                  userName ?? 'Petlander',
                  style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              if (unread > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimalsSection extends StatelessWidget {
  final AsyncValue<List<Animal>> animals;
  const _AnimalsSection({required this.animals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Mes animaux', () => context.push(AppRoutes.animals)),
        const SizedBox(height: 12),
        animals.when(
          loading: () => const SizedBox(height: 220, child: LoadingPaw()),
          error: (e, _) => SizedBox(
            height: 100,
            child: Center(child: Text('Erreur : $e', style: AppTextStyles.bodySmall)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const EmptyState(
                  icon: Icons.pets,
                  title: 'Aucun animal pour l\'instant',
                  subtitle: 'Ajoute ton premier compagnon en cliquant sur +',
                ),
              );
            }
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => FadeInRight(
                  delay: Duration(milliseconds: 80 * i),
                  child: PetCard(
                    width: 180,
                    animal: list[i],
                    onTap: () => context.push(AppRoutes.animalDetail(list[i].id)),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(Icons.calendar_today, 'Rendez-vous', AppColors.secondary,
          () => context.go(AppRoutes.appointments)),
      _QuickAction(Icons.medical_services_outlined, 'Vétérinaires', AppColors.accent,
          () => context.push(AppRoutes.vets)),
      _QuickAction(Icons.alarm_outlined, 'Rappels', AppColors.warning,
          () => context.push(AppRoutes.standardReminders)),
      _QuickAction(Icons.smart_toy_outlined, 'Assistant IA', AppColors.info,
          () => context.push(AppRoutes.vetAssistant), badge: 'NEW'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Accès rapide', null),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: actions.map((a) => _QuickActionTile(action: a)).toList(),
        ),
      ],
    );
  }
}

class _UpcomingAppointments extends StatelessWidget {
  final AsyncValue<List<Appointment>> upcoming;
  const _UpcomingAppointments({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Prochains rendez-vous',
            () => context.push(AppRoutes.appointments)),
        const SizedBox(height: 12),
        upcoming.when(
          loading: () => const SizedBox(height: 80, child: LoadingPaw()),
          error: (e, _) => Text('Erreur : $e'),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_outlined,
                        color: AppColors.primaryDark, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Aucun RDV à venir',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            'Planifie un rendez-vous pour ton animal',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            final visible = list.take(3).toList();
            return Column(
              children: visible.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _UpcomingTile(appointment: a),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final Appointment appointment;
  const _UpcomingTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM • HH:mm', 'fr_FR');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.3),
          child: const Icon(Icons.event, color: AppColors.secondaryDark),
        ),
        title: Text(appointment.motif ?? 'Consultation',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (appointment.animalNom != null) appointment.animalNom!,
            if (appointment.veterinaireNom != null) 'Dr ${appointment.veterinaireNom}',
          ].join(' • '),
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(dateFmt.format(appointment.dateHeure),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

Widget _sectionTitle(BuildContext context, String title, VoidCallback? onSeeAll) {
  return Row(
    children: [
      Expanded(child: Text(title, style: AppTextStyles.headlineMedium)),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: Text('Voir tout',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
        ),
    ],
  );
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'global_search',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(AppRoutes.search),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Text('Rechercher animal, véto, RDV...',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AsyncValue<List<Animal>> animals;
  final AsyncValue<List<Appointment>> upcoming;
  const _StatsRow({required this.animals, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final nbAnimals = animals.valueOrNull?.length ?? 0;
    final nbUpcoming = upcoming.valueOrNull?.length ?? 0;
    final now = DateTime.now();
    final endMonth = DateTime(now.year, now.month + 1, 0, 23, 59);
    final nbThisMonth = (upcoming.valueOrNull ?? [])
        .where((a) => a.dateHeure.isBefore(endMonth))
        .length;

    return Row(
      children: [
        Expanded(
          child: ZoomIn(
            child: _StatCard(
              icon: Icons.pets,
              value: '$nbAnimals',
              label: 'Animaux',
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ZoomIn(
            delay: const Duration(milliseconds: 100),
            child: _StatCard(
              icon: Icons.event,
              value: '$nbUpcoming',
              label: 'RDV à venir',
              color: AppColors.warning,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ZoomIn(
            delay: const Duration(milliseconds: 200),
            child: _StatCard(
              icon: Icons.calendar_month,
              value: '$nbThisMonth',
              label: 'Ce mois',
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineLarge
                  .copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  _QuickAction(this.icon, this.label, this.color, this.onTap, {this.badge});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              if (action.badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(action.badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(action.label,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
