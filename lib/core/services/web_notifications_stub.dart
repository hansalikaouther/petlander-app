// Stub pour les plateformes non-web (mobile/desktop) — ne fait rien.

Future<bool> webRequestPermission() async => false;

Future<void> webShowNotification({
  required String title,
  required String body,
}) async {
  // no-op sur mobile
}
