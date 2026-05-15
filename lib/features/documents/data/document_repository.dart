import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/document_medical.dart';

class DocumentRepository {
  SupabaseClient get _c => SupabaseService.client;
  static const _uuid = Uuid();

  Future<List<DocumentMedical>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('document_medical')
        .select()
        .eq('id_animal', animalId)
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => DocumentMedical.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentMedical> create(DocumentMedical d) async {
    final res = await _c
        .from('document_medical')
        .insert(d.toInsertJson())
        .select()
        .single();
    return DocumentMedical.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('document_medical').delete().eq('id_document', id);
  }

  /// Upload depuis un File (mobile uniquement). Sur web, utiliser uploadBytes.
  Future<String> uploadFile(File file, String userId) async {
    final ext = file.path.split('.').last.toLowerCase();
    return uploadBytes(await file.readAsBytes(), ext, userId);
  }

  /// Upload générique compatible web + mobile (à partir des bytes).
  Future<String> uploadBytes(
      Uint8List bytes, String ext, String userId) async {
    final cleanExt = ext.toLowerCase().replaceAll('.', '');
    final path = '$userId/${_uuid.v4()}.$cleanExt';
    final contentType = _contentTypeFor(cleanExt);
    await _c.storage.from('documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );
    return _c.storage
        .from('documents')
        .createSignedUrl(path, 60 * 60 * 24 * 365);
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
