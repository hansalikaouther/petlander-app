import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/veterinaire.dart';

class VetRepository {
  SupabaseClient get _c => SupabaseService.client;

  Future<List<Veterinaire>> fetchAll(String userId) async {
    final res = await _c
        .from('veterinaire')
        .select()
        .eq('id_utilisateur', userId)
        .order('nom');
    return (res as List)
        .map((e) => Veterinaire.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Veterinaire> fetchById(String id) async {
    final res = await _c.from('veterinaire').select().eq('id_veterinaire', id).single();
    return Veterinaire.fromJson(res);
  }

  Future<Veterinaire> create(Veterinaire vet) async {
    final res = await _c
        .from('veterinaire')
        .insert(vet.toInsertJson())
        .select()
        .single();
    return Veterinaire.fromJson(res);
  }

  Future<Veterinaire> update(String id, Map<String, dynamic> changes) async {
    final res = await _c
        .from('veterinaire')
        .update(changes)
        .eq('id_veterinaire', id)
        .select()
        .single();
    return Veterinaire.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('veterinaire').delete().eq('id_veterinaire', id);
  }
}
