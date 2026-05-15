import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';

/// Gère :
/// - le marquage du dernier jour où le pop-up "conseil du jour" a été affiché
/// - la planification d'un rappel automatique tous les 10 jours
class DailyTipService {
  DailyTipService._();

  static const _kLastShown = 'daily_tip_last_shown';
  static const _kReminderId = 'daily_reminder_scheduled_at';
  static const _kNotifInserted = 'daily_tip_notif_inserted';
  static const int _reminderNotifId = 999001;

  /// Vrai si le pop-up n'a pas encore été affiché aujourd'hui.
  static Future<bool> shouldShowTodayPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLastShown);
    final today = _todayKey();
    return last != today;
  }

  /// Marque le pop-up comme déjà vu pour aujourd'hui.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastShown, _todayKey());
  }

  /// Vrai si une notification Supabase a déjà été insérée aujourd'hui.
  static Future<bool> notifAlreadyInsertedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNotifInserted) == _todayKey();
  }

  /// Marque la notification Supabase comme insérée aujourd'hui.
  static Future<void> markNotifInserted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotifInserted, _todayKey());
  }

  /// Planifie (ou re-planifie) un rappel local dans 10 jours à 10h
  /// pour inviter l'utilisateur à revenir consulter l'application.
  static Future<void> scheduleReminderIn10Days() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kReminderId);

    final next = DateTime.now().add(const Duration(days: 10));
    final scheduled = DateTime(next.year, next.month, next.day, 10);

    // Si déjà planifié pour la même date, on évite de re-planifier
    if (last == scheduled.toIso8601String()) return;

    await NotificationService.cancel(_reminderNotifId);
    await NotificationService.schedule(
      id: _reminderNotifId,
      title: 'On t\'attend chez Petlander !',
      body:
          'Cela fait quelques jours… Viens checker tes compagnons et découvrir le conseil du jour.',
      scheduledAt: scheduled,
    );
    await prefs.setString(_kReminderId, scheduled.toIso8601String());
  }

  static String _todayKey() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
