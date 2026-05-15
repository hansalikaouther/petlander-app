import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/allergie.dart';
import '../data/allergie_repository.dart';

final allergieRepositoryProvider =
    Provider<AllergieRepository>((ref) => AllergieRepository());

final allergieCatalogProvider = FutureProvider<List<Allergie>>((ref) {
  return ref.read(allergieRepositoryProvider).fetchCatalog();
});

final animalAllergiesProvider =
    FutureProvider.family<List<AnimalAllergie>, String>((ref, animalId) {
  return ref.read(allergieRepositoryProvider).fetchByAnimal(animalId);
});
