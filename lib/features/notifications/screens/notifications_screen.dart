import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/notification_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_paw.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'vaccin':
        return Icons.vaccines;
      case 'rdv':
        return Icons.event;
      case 'traitement':
        return Icons.medication_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'vaccin':
        return AppColors.accent;
      case 'rdv':
        return AppColors.warning;
      case 'traitement':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer lu',
            onPressed: () async {
              final user = ref.read(currentAuthUserProvider);
              if (user == null) return;
              try {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markAllRead(user.id);
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Toutes marquées comme lues'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadNotificationsCountProvider);
        },
        child: notifsAsync.when(
          loading: () => const LoadingPaw(),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.notifications_none,
                    title: 'Aucune notification',
                    subtitle: 'Tes rappels (vaccins, RDV) apparaîtront ici',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: 50 * i),
                child: _NotifCard(
                  notif: list[i],
                  icon: _iconForType(list[i].type),
                  color: _colorForType(list[i].type),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotifCard extends ConsumerWidget {
  final NotificationItem notif;
  final IconData icon;
  final Color color;
  const _NotifCard({required this.notif, required this.icon, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(notificationsRepositoryProvider).delete(notif.id);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsCountProvider);
      },
      child: Card(
        color: notif.lue ? null : color.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (!notif.lue) {
              await ref.read(notificationsRepositoryProvider).markRead(notif.id);
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(notif.titre,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ),
                          if (!notif.lue)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (notif.contenu != null) ...[
                        const SizedBox(height: 4),
                        Text(notif.contenu!, style: AppTextStyles.bodySmall),
                      ],
                      const SizedBox(height: 6),
                      Text(dateFmt.format(notif.dateEnvoi),
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
