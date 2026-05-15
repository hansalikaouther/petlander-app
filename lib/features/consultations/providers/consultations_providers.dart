import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/consultation.dart';
import '../data/consultation_repository.dart';

final consultationRepositoryProvider =
    Provider<ConsultationRepository>((ref) => ConsultationRepository());

final consultationsByAnimalProvider =
    FutureProvider.family<List<Consultation>, String>((ref, animalId) {
  return ref.read(consultationRepositoryProvider).fetchByAnimal(animalId);
});

final consultationDetailProvider =
    FutureProvider.family<Consultation, String>((ref, id) {
  return ref.read(consultationRepositoryProvider).fetchById(id);
});
