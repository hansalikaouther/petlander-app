import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/growth_record.dart';

class GrowthRepository {
  SupabaseClient get _c => SupabaseService.client;

  Future<List<GrowthRecord>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('historique_croissance')
        .select()
        .eq('id_animal', animalId)
        .order('date');
    return (res as List)
        .map((e) => GrowthRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GrowthRecord> create(GrowthRecord g) async {
    final res = await _c
        .from('historique_croissance')
        .insert(g.toInsertJson())
        .select()
        .single();
    return GrowthRecord.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('historique_croissance').delete().eq('id', id);
  }
}
