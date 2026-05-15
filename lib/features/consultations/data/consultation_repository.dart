import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/consultation.dart';

class ConsultationRepository {
  SupabaseClient get _c => SupabaseService.client;

  static const _selectWithJoins = '*, veterinaire(nom), animal(nom)';

  Future<List<Consultation>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('consultation')
        .select(_selectWithJoins)
        .eq('id_animal', animalId)
        .order('date_consultation', ascending: false);
    return (res as List)
        .map((e) => Consultation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Consultation> fetchById(String id) async {
    final res = await _c
        .from('consultation')
        .select(_selectWithJoins)
        .eq('id_consultation', id)
        .single();
    return Consultation.fromJson(res);
  }

  Future<Consultation> create(Consultation c) async {
    final res = await _c
        .from('consultation')
        .insert(c.toInsertJson())
        .select(_selectWithJoins)
        .single();
    return Consultation.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('consultation').delete().eq('id_consultation', id);
  }
}
