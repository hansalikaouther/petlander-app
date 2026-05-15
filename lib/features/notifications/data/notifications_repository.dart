import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/notification_item.dart';

class NotificationsRepository {
  SupabaseClient get _c => SupabaseService.client;

  Future<List<NotificationItem>> fetchAll(String userId) async {
    final res = await _c
        .from('notification')
        .select()
        .eq('id_utilisateur', userId)
        .order('date_envoi', ascending: false);
    return (res as List)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> countUnread(String userId) async {
    final res = await _c
        .from('notification')
        .select('id_notification')
        .eq('id_utilisateur', userId)
        .eq('lue', false);
    return (res as List).length;
  }

  Future<void> markRead(String id) async {
    await _c.from('notification').update({'lue': true}).eq('id_notification', id);
  }

  Future<void> markAllRead(String userId) async {
    await _c
        .from('notification')
        .update({'lue': true})
        .eq('id_utilisateur', userId)
        .eq('lue', false);
  }

  Future<void> create({
    required String userId,
    required String titre,
    String? contenu,
    String? type,
  }) async {
    final data = <String, dynamic>{
      'id_utilisateur': userId,
      'titre': titre,
      'date_envoi': DateTime.now().toIso8601String(),
      'lue': false,
    };
    if (contenu != null) data['contenu'] = contenu;
    if (type != null) data['type'] = type;
    await _c.from('notification').insert(data);
  }

  Future<void> delete(String id) async {
    await _c.from('notification').delete().eq('id_notification', id);
  }
}
