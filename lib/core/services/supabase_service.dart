import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper centralisé autour du client Supabase.
///
/// Initialiser via [SupabaseService.init] dans le `main()` après
/// le chargement du `.env` (URL et ANON_KEY).
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  // Fallback values (anon key is safe to expose - it's the public client key
  // already shipped in every Flutter web build).
  static const _fallbackUrl = 'https://qtfkmclbbinuflembpob.supabase.co';
  static const _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0ZmttY2xiYmludWZsZW1icG9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NTgxNTksImV4cCI6MjA5MzEzNDE1OX0.Ds6fAdB_cRTxyYdNWAMlPdQoH33u51A24HV6cz0j7wQ';

  static Future<void> init() async {
    // Prefer .env if available (local dev), otherwise use hardcoded fallback
    // (needed on Netlify which blocks hidden files like .env).
    String url = _fallbackUrl;
    String anonKey = _fallbackAnonKey;
    try {
      final envUrl = dotenv.env['SUPABASE_URL'];
      final envKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (envUrl != null && envUrl.isNotEmpty) url = envUrl;
      if (envKey != null && envKey.isNotEmpty) anonKey = envKey;
    } catch (_) {
      // dotenv not loaded or .env not accessible — keep fallback values
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
