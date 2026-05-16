// Implementation web qui utilise l'API Notification du navigateur.
// Compilee uniquement sur web grace a `dart:html`.

// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> webRequestPermission() async {
  if (html.Notification.supported) {
    final perm = await html.Notification.requestPermission();
    return perm == 'granted';
  }
  return false;
}

Future<void> webShowNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;
  html.Notification(
    title,
    body: body,
    icon: 'icons/Icon-192.png',
  );
}
