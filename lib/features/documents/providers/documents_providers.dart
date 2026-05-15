import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/document_medical.dart';
import '../data/document_repository.dart';

final documentRepositoryProvider =
    Provider<DocumentRepository>((ref) => DocumentRepository());

final documentsByAnimalProvider =
    FutureProvider.family<List<DocumentMedical>, String>((ref, animalId) {
  return ref.read(documentRepositoryProvider).fetchByAnimal(animalId);
});
