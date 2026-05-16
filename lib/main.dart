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
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Locale française pour intl (formats de date)
    await initializeDateFormatting('fr_FR', null);

    // Variables d'environnement (Supabase URL & key) — optionnel
    // Sur Netlify, le .env est bloqué (fichier caché). SupabaseService a un fallback.
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('[main] .env not loaded (using fallback): $e');
    }

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

    // Notifications locales (no-op sur web)
    try {
      await NotificationService.init();
      await NotificationService.requestPermissions();
    } catch (e) {
      debugPrint('[main] NotificationService init failed (non-critical): $e');
    }

    runApp(const ProviderScope(child: PetlanderApp()));
  } catch (e, stack) {
    debugPrint('[main] FATAL: $e\n$stack');
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text('Erreur de démarrage Petlander',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                Text('$e', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 24),
                const Text('Stack trace :', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$stack', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
