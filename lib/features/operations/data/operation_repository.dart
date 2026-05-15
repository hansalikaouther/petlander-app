import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../shared/models/operation.dart';

class OperationRepository {
  SupabaseClient get _c => SupabaseService.client;

  static const _selectWithJoins = '*, veterinaire(nom)';

  Future<List<Operation>> fetchByAnimal(String animalId) async {
    final res = await _c
        .from('operation_chirurgicale')
        .select(_selectWithJoins)
        .eq('id_animal', animalId)
        .order('date_operation', ascending: false);
    return (res as List)
        .map((e) => Operation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Operation> create(Operation op) async {
    final res = await _c
        .from('operation_chirurgicale')
        .insert(op.toInsertJson())
        .select(_selectWithJoins)
        .single();
    return Operation.fromJson(res);
  }

  Future<void> delete(String id) async {
    await _c.from('operation_chirurgicale').delete().eq('id_operation', id);
  }
}
