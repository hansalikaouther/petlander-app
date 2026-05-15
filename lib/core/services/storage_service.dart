import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Wrapper pour l'upload/download de fichiers (photos animaux,
/// ordonnances, documents médicaux) vers Supabase Storage.
class StorageService {
  StorageService._();

  static const String animalsBucket = 'animals';
  static const String documentsBucket = 'documents';
  static const String avatarsBucket = 'avatars';

  static SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  /// Upload un fichier et retourne son URL publique.
  static Future<String> uploadFile({
    required String bucket,
    required File file,
    String? folder,
  }) async {
    final ext = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$ext';
    final path = folder != null ? '$folder/$fileName' : fileName;

    await _client.storage.from(bucket).upload(path, file);
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }
}
