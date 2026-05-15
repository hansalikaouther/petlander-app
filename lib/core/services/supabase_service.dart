import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper centralisé autour du client Supabase.
///
/// Initialiser via [SupabaseService.init] dans le `main()` après
/// le chargement du `.env` (URL et ANON_KEY).
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'Variables SUPABASE_URL et SUPABASE_ANON_KEY manquantes dans le fichier .env',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
}
