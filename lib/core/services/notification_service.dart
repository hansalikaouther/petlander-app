import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Import conditionnel : utilise dart:html sur web, stub sur mobile
import 'web_notifications_stub.dart'
    if (dart.library.html) 'web_notifications_impl.dart' as web_notif;

/// Gestion centralisée des notifications.
///
/// - **Mobile** (Android/iOS) : notifications locales planifiées via
///   `flutter_local_notifications`. Fonctionnent en foreground et background
///   tant que l'app n'est pas tuée.
/// - **Web** : utilise l'API Notification du navigateur (foreground uniquement).
///   La planification (`schedule`) est ignorée sur web, mais `showNow` affiche
///   bien une notification système.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'petlander_default';
  static const String _channelName = 'Petlander - Rappels';
  static const String _channelDescription =
      'Notifications pour vaccins, RDV, traitements et alertes santé';

  static Future<void> init() async {
    if (kIsWeb) return; // initialisation natif pas applicable sur web

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
    if (kIsWeb) {
      await web_notif.webRequestPermission();
      return;
    }
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
  /// Fonctionne sur mobile ET sur web (via API Notification du navigateur).
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      await web_notif.webShowNotification(title: title, body: body);
      return;
    }
    await _plugin.show(id, title, body, _details);
  }

  /// Programme une notification à une date/heure précise.
  /// Sur web : ignorée (les notifications planifiées nécessitent un Service Worker).
  /// Sur mobile : utilise `inexactAllowWhileIdle` pour éviter le besoin de la
  /// permission SCHEDULE_EXACT_ALARM (Android 13+) qui est restreinte aux apps
  /// type réveil/calendrier.
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
