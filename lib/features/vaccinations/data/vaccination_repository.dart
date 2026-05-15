import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/vaccination.dart';

class VaccinationRepository {
  SupabaseClient get _c => SupabaseService.client;

  Future<List<Vaccination>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('vaccination')
        .select()
        .eq('id_animal', animalId)
        .order('date_vaccination', ascending: false);
    return (res as List)
        .map((e) => Vaccination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vaccination> create(Vaccination v) async {
    final res = await _c.from('vaccination').insert(v.toInsertJson()).select().single();
    return Vaccination.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('vaccination').delete().eq('id_vaccination', id);
  }

  /// Liste des vaccins du référentiel filtrés par type d'animal
  /// (chien, chat, ou tous).
  Future<List<VaccinReference>> fetchVaccinReferences({String? typeAnimal}) async {
    final base = _c.from('vaccin').select();
    final filtered = typeAnimal != null
        ? base.or('type_animal.eq.$typeAnimal,type_animal.eq.tous,type_animal.is.null')
        : base;
    final res = await filtered.order('nom_vaccin');
    return (res as List)
        .map((e) => VaccinReference.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retourne tous les rappels à venir dans les `daysAhead` prochains jours
  /// pour les animaux du user (utile pour le dashboard).
  Future<List<Vaccination>> fetchUpcomingReminders(String userId, {int daysAhead = 60}) async {
    final today = DateTime.now();
    final until = today.add(Duration(days: daysAhead));
    final res = await _c
        .from('vaccination')
        .select('*, animal!inner(id_utilisateur)')
        .eq('animal.id_utilisateur', userId)
        .gte('date_rappel', today.toIso8601String().split('T').first)
        .lte('date_rappel', until.toIso8601String().split('T').first)
        .order('date_rappel');
    return (res as List)
        .map((e) => Vaccination.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
