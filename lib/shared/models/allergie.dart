/// Modèle Allergie + AvoirAllergie (jointure animal ↔ allergie).
class Allergie {
  final String id;
  final String nom;
  final String? observation;

  const Allergie({required this.id, required this.nom, this.observation});

  factory Allergie.fromJson(Map<String, dynamic> json) => Allergie(
        id: json['id_allergie'] as String,
        nom: json['nom'] as String,
        observation: json['obs'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'nom': nom,
        if (observation != null) 'obs': observation,
      };
}

/// Vue jointe (utilisée dans l'écran Allergies d'un animal).
class AnimalAllergie {
  final String idAllergie;
  final String idAnimal;
  final String nom;
  final String? observation;
  final DateTime? dateDetection;
  final String? notes;

  const AnimalAllergie({
    required this.idAllergie,
    required this.idAnimal,
    required this.nom,
    this.observation,
    this.dateDetection,
    this.notes,
  });

  factory AnimalAllergie.fromJoinedJson(Map<String, dynamic> json) {
    final allergie = json['allergie'] as Map<String, dynamic>;
    return AnimalAllergie(
      idAllergie: json['id_allergie'] as String,
      idAnimal: json['id_animal'] as String,
      nom: allergie['nom'] as String,
      observation: allergie['obs'] as String?,
      dateDetection: json['date_detection'] != null
          ? DateTime.parse(json['date_detection'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
