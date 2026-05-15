import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/notification_item.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => NotificationsRepository());

final notificationsProvider =
    FutureProvider<List<NotificationItem>>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return [];
  return ref.read(notificationsRepositoryProvider).fetchAll(user.id);
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return 0;
  return ref.read(notificationsRepositoryProvider).countUnread(user.id);
});
