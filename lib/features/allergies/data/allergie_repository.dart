import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/allergie.dart';

class AllergieRepository {
  SupabaseClient get _c => SupabaseService.client;

  /// Toutes les allergies du référentiel global.
  Future<List<Allergie>> fetchCatalog() async {
    final res = await _c.from('allergie').select().order('nom');
    return (res as List)
        .map((e) => Allergie.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Allergies d'un animal (jointure avoir_allergie + allergie).
  Future<List<AnimalAllergie>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('avoir_allergie')
        .select('id_allergie, id_animal, date_detection, notes, '
            'allergie:allergie(nom, obs)')
        .eq('id_animal', animalId);
    return (res as List)
        .map((e) => AnimalAllergie.fromJoinedJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée une nouvelle allergie dans le référentiel et retourne son id.
  Future<String> createInCatalog(String nom, String? observation) async {
    final payload = <String, dynamic>{'nom': nom};
    if (observation != null) payload['obs'] = observation;
    final res = await _c.from('allergie').insert(payload).select().single();
    return res['id_allergie'] as String;
  }

  /// Lie une allergie à un animal.
  Future<void> attachToAnimal({
    required String animalId,
    required String allergieId,
    DateTime? dateDetection,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'id_animal': animalId,
      'id_allergie': allergieId,
    };
    if (dateDetection != null) {
      payload['date_detection'] =
          dateDetection.toIso8601String().split('T').first;
    }
    if (notes != null) payload['notes'] = notes;
    await _c.from('avoir_allergie').insert(payload);
  }

  Future<void> detachFromAnimal({
    required String animalId,
    required String allergieId,
  }) async {
    await _c
        .from('avoir_allergie')
        .delete()
        .eq('id_animal', animalId)
        .eq('id_allergie', allergieId);
  }
}
