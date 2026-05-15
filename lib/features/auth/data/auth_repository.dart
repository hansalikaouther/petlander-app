import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/app_user.dart';

/// Repository centralisant les appels d'authentification Supabase
/// et la lecture/mise à jour du profil `utilisateur`.
class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Set to true in main() when the launch URL contains type=recovery,
  /// before Supabase.initialize() consumes and clears the hash.
  static bool pendingRecovery = false;

  AuthChangeEvent? lastEvent;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) {
        lastEvent = state.event;
        return state;
      });

  void clearLastEvent() {
    lastEvent = null;
    AuthRepository.pendingRecovery = false;
  }

  User? get currentAuthUser => _client.auth.currentUser;

  /// Vérifie si la session courante a été établie via un lien de reset.
  /// Lit le claim AMR du JWT — fiable même si l'événement stream a été manqué.
  bool get isRecoverySession {
    if (AuthRepository.pendingRecovery) return true;
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final amr = claims['amr'];
      if (amr is List) {
        return amr.any((e) => e is Map && e['method'] == 'recovery');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Inscription : email + password + metadata (nom, téléphone, adresse).
  /// Le trigger `handle_new_user` crée la ligne dans `utilisateur` automatiquement.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nom,
    String? numeroTelephone,
    String? adresse,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nom': nom,
        if (numeroTelephone != null && numeroTelephone.isNotEmpty)
          'numero_telephone': numeroTelephone,
        if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) async {
    debugPrint('[Auth] resetPassword pour $email');
    // redirectTo must match the running app URL exactly (scheme+host+port).
    // On web, Uri.base.origin gives e.g. "http://localhost:8080".
    final redirectTo = kIsWeb ? Uri.base.origin : null;
    debugPrint('[Auth] redirectTo=$redirectTo');
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    debugPrint('[Auth] resetPassword OK — email envoyé par Supabase');
  }

  /// Vérifie le code OTP à 6 chiffres reçu par email après inscription.
  /// Si la vérification réussit, l'utilisateur est automatiquement connecté.
  Future<AuthResponse> verifySignUpOtp({
    required String email,
    required String code,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.signup,
    );
  }

  /// Renvoie un nouveau code OTP de confirmation d'email.
  Future<void> resendSignUpOtp(String email) {
    return _client.auth.resend(type: OtpType.signup, email: email);
  }

  /// Change le mot de passe de l'utilisateur connecté.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Supprime DÉFINITIVEMENT le compte de l'utilisateur connecté
  /// (ses données + son entrée auth.users). Action irréversible.
  /// Appelle la fonction Postgres `delete_user_account()` (cf. 06_delete_account.sql).
  Future<void> deleteAccount() async {
    await _client.rpc('delete_user_account');
    await _client.auth.signOut();
  }

  /// Récupère le profil utilisateur (table `utilisateur`).
  Future<AppUser?> fetchProfile(String userId) async {
    final res = await _client
        .from('utilisateur')
        .select()
        .eq('id_utilisateur', userId)
        .maybeSingle();
    if (res == null) return null;
    return AppUser.fromJson(res);
  }

  Future<AppUser> updateProfile(AppUser user) async {
    final res = await _client
        .from('utilisateur')
        .update(user.toJson()..remove('id_utilisateur')..remove('email'))
        .eq('id_utilisateur', user.id)
        .select()
        .single();
    return AppUser.fromJson(res);
  }
}
