import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/examen.dart';

class ExamenRepository {
  SupabaseClient get _c => SupabaseService.client;

  Future<List<Examen>> fetchByConsultation(String consultationId) async {
    final res = await _c
        .from('examen')
        .select()
        .eq('id_consultation', consultationId)
        .order('date', ascending: false);
    return (res as List)
        .map((e) => Examen.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Examen> create(Examen e) async {
    final res = await _c.from('examen').insert(e.toInsertJson()).select().single();
    return Examen.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('examen').delete().eq('id_examen', id);
  }
}
