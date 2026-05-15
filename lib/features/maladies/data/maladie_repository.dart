import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/maladie_chronique.dart';

class MaladieRepository {
  SupabaseClient get _c => SupabaseService.client;

  Future<List<MaladieChronique>> fetchCatalog() async {
    final res =
        await _c.from('maladie_chronique').select().order('nom_maladie');
    return (res as List)
        .map((e) => MaladieChronique.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AnimalMaladie>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('avoir_maladie_chronique')
        .select('id_maladie, id_animal, date_diagnostic, notes, '
            'maladie_chronique:maladie_chronique(nom_maladie, description)')
        .eq('id_animal', animalId);
    return (res as List)
        .map((e) => AnimalMaladie.fromJoinedJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createInCatalog(String nom, String? description) async {
    final payload = <String, dynamic>{'nom_maladie': nom};
    if (description != null) payload['description'] = description;
    final res =
        await _c.from('maladie_chronique').insert(payload).select().single();
    return res['id_maladie'] as String;
  }

  Future<void> attachToAnimal({
    required String animalId,
    required String maladieId,
    DateTime? dateDiagnostic,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'id_animal': animalId,
      'id_maladie': maladieId,
    };
    if (dateDiagnostic != null) {
      payload['date_diagnostic'] =
          dateDiagnostic.toIso8601String().split('T').first;
    }
    if (notes != null) payload['notes'] = notes;
    await _c.from('avoir_maladie_chronique').insert(payload);
  }

  Future<void> detachFromAnimal({
    required String animalId,
    required String maladieId,
  }) async {
    await _c
        .from('avoir_maladie_chronique')
        .delete()
        .eq('id_animal', animalId)
        .eq('id_maladie', maladieId);
  }
}
