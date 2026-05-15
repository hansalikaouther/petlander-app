/// Modèle Document médical (table `document_medical`).
class DocumentMedical {
  final String id;
  final String idAnimal;
  final String titre;
  final String? typeDocument;
  final String fichierUrl;
  final DateTime? dateDocument;
  final String? notes;
  final DateTime? createdAt;

  const DocumentMedical({
    required this.id,
    required this.idAnimal,
    required this.titre,
    this.typeDocument,
    required this.fichierUrl,
    this.dateDocument,
    this.notes,
    this.createdAt,
  });

  factory DocumentMedical.fromJson(Map<String, dynamic> json) =>
      DocumentMedical(
        id: json['id_document'] as String,
        idAnimal: json['id_animal'] as String,
        titre: json['titre'] as String,
        typeDocument: json['type_document'] as String?,
        fichierUrl: json['fichier_url'] as String,
        dateDocument: json['date_document'] != null
            ? DateTime.parse(json['date_document'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'id_animal': idAnimal,
        'titre': titre,
        'type_document': typeDocument,
        'fichier_url': fichierUrl,
        'date_document': dateDocument?.toIso8601String().split('T').first,
        'notes': notes,
      };

  bool get isImage {
    final ext = fichierUrl.split('?').first.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
  }
}
