/// Modèle Examen (table `examen`).
class Examen {
  final String id;
  final String idConsultation;
  final String typeExamen;
  final DateTime date;
  final String? compteRendu;
  final String? documentUrl;
  final DateTime? createdAt;

  const Examen({
    required this.id,
    required this.idConsultation,
    required this.typeExamen,
    required this.date,
    this.compteRendu,
    this.documentUrl,
    this.createdAt,
  });

  factory Examen.fromJson(Map<String, dynamic> json) => Examen(
        id: json['id_examen'] as String,
        idConsultation: json['id_consultation'] as String,
        typeExamen: json['type_examen'] as String,
        date: DateTime.parse(json['date'] as String),
        compteRendu: json['compte_rendu'] as String?,
        documentUrl: json['document_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'id_consultation': idConsultation,
        'type_examen': typeExamen,
        'date': date.toIso8601String().split('T').first,
        'compte_rendu': compteRendu,
        'document_url': documentUrl,
      };
}
