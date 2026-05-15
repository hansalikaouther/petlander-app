import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Gestion centralisée des notifications locales (rappels vaccins, RDV, traitements).
///
/// Sur Web : les notifications locales ne sont pas supportées par
/// flutter_local_notifications. Toutes les méthodes retournent sans erreur
/// (no-op) pour éviter tout crash. Sur mobile (Android/iOS), les notifications
/// fonctionnent en foreground et background, mais PAS si l'app est tuée.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'petlander_default';
  static const String _channelName = 'Petlander - Rappels';
  static const String _channelDescription =
      'Notifications pour vaccins, RDV, traitements et alertes santé';

  static Future<void> init() async {
    if (kIsWeb) return; // flutter_local_notifications ne supporte pas le web

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await Permission.notification.request();
  }

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Affiche une notification immédiate.
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(id, title, body, _details);
  }

  /// Programme une notification à une date/heure précise.
  /// Ne fonctionne que sur Android/iOS avec l'app en arrière-plan.
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (kIsWeb) return;
    if (scheduledAt.isBefore(DateTime.now())) return;
    final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}
