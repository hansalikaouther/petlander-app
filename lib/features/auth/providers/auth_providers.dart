import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/app_user.dart';
import '../data/auth_repository.dart';

/// Repository singleton.
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Stream de l'état d'auth Supabase (réagit aux signin/signout).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// User Supabase courant (null si déconnecté).
final currentAuthUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateChangesProvider);
  return state.maybeWhen(
    data: (s) => s.session?.user,
    orElse: () => ref.read(authRepositoryProvider).currentAuthUser,
  );
});

/// Profil applicatif (table `utilisateur`) — chargé après login.
final currentProfileProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return null;
  return ref.read(authRepositoryProvider).fetchProfile(user.id);
});
