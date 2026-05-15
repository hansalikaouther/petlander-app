import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/operation.dart';
import '../data/operation_repository.dart';

final operationRepositoryProvider =
    Provider<OperationRepository>((ref) => OperationRepository());

final operationsByAnimalProvider =
    FutureProvider.family<List<Operation>, String>((ref, animalId) {
  return ref.read(operationRepositoryProvider).fetchByAnimal(animalId);
});
