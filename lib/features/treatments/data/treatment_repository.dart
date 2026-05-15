import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/traitement.dart';

class TreatmentRepository {
  SupabaseClient get _c => SupabaseService.client;
  static const _uuid = Uuid();

  Future<List<Traitement>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('traitement')
        .select()
        .eq('id_animal', animalId)
        .order('date_debut', ascending: false);
    return (res as List)
        .map((e) => Traitement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Traitement>> fetchByConsultation(String consultationId) async {
    final res = await _c
        .from('traitement')
        .select()
        .eq('id_consultation', consultationId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => Traitement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Traitement> create(Traitement t) async {
    final res = await _c.from('traitement').insert(t.toInsertJson()).select().single();
    return Traitement.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('traitement').delete().eq('id_traitement', id);
  }

  /// Upload de la photo d'ordonnance dans le bucket `documents`.
  Future<String> uploadOrdo(File file, String userId) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$userId/ordo/${_uuid.v4()}.$ext';
    await _c.storage.from('documents').upload(path, file);
    return _c.storage.from('documents').createSignedUrl(path, 60 * 60 * 24 * 365);
  }
}
