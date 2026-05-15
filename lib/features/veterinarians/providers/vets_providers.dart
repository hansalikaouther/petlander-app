import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/veterinaire.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/vet_repository.dart';

final vetRepositoryProvider = Provider<VetRepository>((ref) => VetRepository());

final vetsProvider = FutureProvider<List<Veterinaire>>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return [];
  return ref.read(vetRepositoryProvider).fetchAll(user.id);
});
