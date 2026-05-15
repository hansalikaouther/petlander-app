/// Modèle Opération chirurgicale (table `operation_chirurgicale`).
class Operation {
  final String id;
  final String idAnimal;
  final String? idVeterinaire;
  final String typeOperation;
  final DateTime dateOperation;
  final String? duree;
  final bool notification;
  final String? compteRendu;
  final List<String> documentsUrl;
  final DateTime? createdAt;

  /// Joints
  final String? veterinaireNom;

  const Operation({
    required this.id,
    required this.idAnimal,
    this.idVeterinaire,
    required this.typeOperation,
    required this.dateOperation,
    this.duree,
    this.notification = false,
    this.compteRendu,
    this.documentsUrl = const [],
    this.createdAt,
    this.veterinaireNom,
  });

  factory Operation.fromJson(Map<String, dynamic> json) {
    final vet = json['veterinaire'] as Map<String, dynamic>?;
    final docs = json['documents_url'];
    return Operation(
      id: json['id_operation'] as String,
      idAnimal: json['id_animal'] as String,
      idVeterinaire: json['id_veterinaire'] as String?,
      typeOperation: json['type_operation'] as String,
      dateOperation: DateTime.parse(json['date_operation'] as String),
      duree: json['duree'] as String?,
      notification: json['notification'] as bool? ?? false,
      compteRendu: json['compte_rendu'] as String?,
      documentsUrl: docs is List ? docs.map((e) => e.toString()).toList() : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      veterinaireNom: vet?['nom'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'id_animal': idAnimal,
        'id_veterinaire': idVeterinaire,
        'type_operation': typeOperation,
        'date_operation': dateOperation.toIso8601String().split('T').first,
        'duree': duree,
        'notification': notification,
        'compte_rendu': compteRendu,
        'documents_url': documentsUrl,
      };
}
