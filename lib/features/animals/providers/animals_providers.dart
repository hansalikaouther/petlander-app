import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/animal.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/animal_repository.dart';

final animalRepositoryProvider = Provider<AnimalRepository>((ref) => AnimalRepository());

/// Liste des animaux du user connecté.
final animalsProvider = FutureProvider<List<Animal>>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return [];
  return ref.read(animalRepositoryProvider).fetchAll(user.id);
});

/// Détail d'un animal par id.
final animalDetailProvider = FutureProvider.family<Animal, String>((ref, id) {
  return ref.read(animalRepositoryProvider).fetchById(id);
});
