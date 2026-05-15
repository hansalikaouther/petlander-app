import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/traitement.dart';
import '../data/treatment_repository.dart';

final treatmentRepositoryProvider =
    Provider<TreatmentRepository>((ref) => TreatmentRepository());

final treatmentsByAnimalProvider =
    FutureProvider.family<List<Traitement>, String>((ref, animalId) {
  return ref.read(treatmentRepositoryProvider).fetchByAnimal(animalId);
});

final treatmentsByConsultationProvider =
    FutureProvider.family<List<Traitement>, String>((ref, consultationId) {
  return ref.read(treatmentRepositoryProvider).fetchByConsultation(consultationId);
});
