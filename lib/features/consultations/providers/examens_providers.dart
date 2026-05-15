import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/examen.dart';
import '../data/examen_repository.dart';

final examenRepositoryProvider =
    Provider<ExamenRepository>((ref) => ExamenRepository());

final examensByConsultationProvider =
    FutureProvider.family<List<Examen>, String>((ref, consultationId) {
  return ref.read(examenRepositoryProvider).fetchByConsultation(consultationId);
});
