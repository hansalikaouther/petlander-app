import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/vaccination.dart';
import '../data/vaccination_repository.dart';

final vaccinationRepositoryProvider =
    Provider<VaccinationRepository>((ref) => VaccinationRepository());

/// Liste des vaccinations d'un animal.
final vaccinationsByAnimalProvider =
    FutureProvider.family<List<Vaccination>, String>((ref, animalId) {
  return ref.read(vaccinationRepositoryProvider).fetchByAnimal(animalId);
});

/// Référentiel des vaccins (filtré par type d'animal).
final vaccinReferencesProvider =
    FutureProvider.family<List<VaccinReference>, String?>((ref, typeAnimal) {
  return ref.read(vaccinationRepositoryProvider).fetchVaccinReferences(typeAnimal: typeAnimal);
});
