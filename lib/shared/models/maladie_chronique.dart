/// Modèle MaladieChronique + AvoirMaladieChronique.
class MaladieChronique {
  final String id;
  final String nom;
  final String? description;

  const MaladieChronique({
    required this.id,
    required this.nom,
    this.description,
  });

  factory MaladieChronique.fromJson(Map<String, dynamic> json) =>
      MaladieChronique(
        id: json['id_maladie'] as String,
        nom: json['nom_maladie'] as String,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'nom_maladie': nom,
        if (description != null) 'description': description,
      };
}

/// Vue jointe pour l'écran d'un animal.
class AnimalMaladie {
  final String idMaladie;
  final String idAnimal;
  final String nom;
  final String? description;
  final DateTime? dateDiagnostic;
  final String? notes;

  const AnimalMaladie({
    required this.idMaladie,
    required this.idAnimal,
    required this.nom,
    this.description,
    this.dateDiagnostic,
    this.notes,
  });

  factory AnimalMaladie.fromJoinedJson(Map<String, dynamic> json) {
    final m = json['maladie_chronique'] as Map<String, dynamic>;
    return AnimalMaladie(
      idMaladie: json['id_maladie'] as String,
      idAnimal: json['id_animal'] as String,
      nom: m['nom_maladie'] as String,
      description: m['description'] as String?,
      dateDiagnostic: json['date_diagnostic'] != null
          ? DateTime.parse(json['date_diagnostic'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
