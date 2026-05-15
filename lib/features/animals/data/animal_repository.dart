import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/animal.dart';

class AnimalRepository {
  SupabaseClient get _c => SupabaseService.client;
  static const _uuid = Uuid();

  Future<List<Animal>> fetchAll(String userId) async {
    final res = await _c
        .from('animal')
        .select()
        .eq('id_utilisateur', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Animal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Animal> fetchById(String id) async {
    final res = await _c.from('animal').select().eq('id_animal', id).single();
    return Animal.fromJson(res);
  }

  Future<Animal> create(Animal animal) async {
    final res = await _c.from('animal').insert(animal.toInsertJson()).select().single();
    return Animal.fromJson(res);
  }

  Future<Animal> update(String id, Map<String, dynamic> changes) async {
    final res = await _c.from('animal').update(changes).eq('id_animal', id).select().single();
    return Animal.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('animal').delete().eq('id_animal', id);
  }

  /// Upload depuis bytes (compatible web). ext = 'jpg', 'png', etc.
  Future<String> uploadPhotoBytes(
      Uint8List bytes, String ext, String userId) async {
    final path = '$userId/${_uuid.v4()}.$ext';
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    await _c.storage
        .from('animals')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    return _c.storage.from('animals').getPublicUrl(path);
  }

  /// Upload une photo depuis un File (mobile uniquement).
  Future<String> uploadPhoto(File file, String userId) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$userId/${_uuid.v4()}.$ext';
    await _c.storage.from('animals').upload(path, file);
    return _c.storage.from('animals').getPublicUrl(path);
  }
}
