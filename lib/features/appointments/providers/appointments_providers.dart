import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/appointment.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/appointment_repository.dart';

final appointmentRepositoryProvider =
    Provider<AppointmentRepository>((ref) => AppointmentRepository());

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return [];
  return ref.read(appointmentRepositoryProvider).fetchAll(user.id);
});

final upcomingAppointmentsProvider =
    FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return [];
  return ref.read(appointmentRepositoryProvider).fetchUpcoming(user.id);
});

final appointmentsByAnimalProvider =
    FutureProvider.family<List<Appointment>, String>((ref, animalId) {
  return ref.read(appointmentRepositoryProvider).fetchByAnimal(animalId);
});
