import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/appointment.dart';

class AppointmentRepository {
  SupabaseClient get _c => SupabaseService.client;

  /// Sélection enrichie avec les noms d'animal et de vétérinaire (joints).
  static const _selectWithJoins =
      '*, animal(nom), veterinaire(nom)';

  Future<List<Appointment>> fetchAll(String userId) async {
    final res = await _c
        .from('rdv')
        .select(_selectWithJoins)
        .eq('id_utilisateur', userId)
        .order('date_heure');
    return (res as List)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('rdv')
        .select(_selectWithJoins)
        .eq('id_animal', animalId)
        .order('date_heure');
    return (res as List)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Appointment>> fetchUpcoming(String userId) async {
    final now = DateTime.now().toIso8601String();
    final res = await _c
        .from('rdv')
        .select(_selectWithJoins)
        .eq('id_utilisateur', userId)
        .gte('date_heure', now)
        .neq('statut', 'annule')
        .order('date_heure');
    return (res as List)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> create(Appointment apt) async {
    final res = await _c
        .from('rdv')
        .insert(apt.toInsertJson())
        .select(_selectWithJoins)
        .single();
    return Appointment.fromJson(res);
  }

  Future<Appointment> updateStatus(String id, AppointmentStatus statut) async {
    final res = await _c
        .from('rdv')
        .update({'statut': statut.dbValue})
        .eq('id_rdv', id)
        .select(_selectWithJoins)
        .single();
    return Appointment.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('rdv').delete().eq('id_rdv', id);
  }
}
