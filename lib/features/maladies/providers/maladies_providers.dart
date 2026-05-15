import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/maladie_chronique.dart';
import '../data/maladie_repository.dart';

final maladieRepositoryProvider =
    Provider<MaladieRepository>((ref) => MaladieRepository());

final maladieCatalogProvider = FutureProvider<List<MaladieChronique>>((ref) {
  return ref.read(maladieRepositoryProvider).fetchCatalog();
});

final animalMaladiesProvider =
    FutureProvider.family<List<AnimalMaladie>, String>((ref, animalId) {
  return ref.read(maladieRepositoryProvider).fetchByAnimal(animalId);
});
