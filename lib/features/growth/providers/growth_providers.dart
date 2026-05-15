import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/growth_record.dart';
import '../data/growth_repository.dart';

final growthRepositoryProvider =
    Provider<GrowthRepository>((ref) => GrowthRepository());

final growthByAnimalProvider =
    FutureProvider.family<List<GrowthRecord>, String>((ref, animalId) {
  return ref.read(growthRepositoryProvider).fetchByAnimal(animalId);
});
