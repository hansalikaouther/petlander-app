import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/data/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale française pour intl (formats de date)
  await initializeDateFormatting('fr_FR', null);

  // Variables d'environnement (Supabase URL & key)
  await dotenv.load(fileName: '.env');

  // Detect password-recovery link BEFORE Supabase.initialize() clears the hash.
  if (kIsWeb) {
    try {
      final params = Uri.splitQueryString(Uri.base.fragment);
      if (params['type'] == 'recovery') {
        AuthRepository.pendingRecovery = true;
      }
    } catch (_) {}
  }

  // Initialisation Supabase
  await SupabaseService.init();

  // Notifications locales
  await NotificationService.init();
  await NotificationService.requestPermissions();

  runApp(const ProviderScope(child: PetlanderApp()));
}
