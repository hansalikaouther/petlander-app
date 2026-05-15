/// Modèle Vaccination (table `vaccination`).
class Vaccination {
  final String id;
  final String idAnimal;
  final String? idVaccin;
  final String? nomVaccin;
  final DateTime dateVaccination;
  final DateTime? dateRappel;
  final String? idVeterinaire;
  final String? lotVaccin;
  final String? notes;

  const Vaccination({
    required this.id,
    required this.idAnimal,
    this.idVaccin,
    this.nomVaccin,
    required this.dateVaccination,
    this.dateRappel,
    this.idVeterinaire,
    this.lotVaccin,
    this.notes,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) => Vaccination(
        id: json['id_vaccination'] as String,
        idAnimal: json['id_animal'] as String,
        idVaccin: json['id_vaccin'] as String?,
        nomVaccin: json['nom_vaccin'] as String?,
        dateVaccination: DateTime.parse(json['date_vaccination'] as String),
        dateRappel: json['date_rappel'] != null
            ? DateTime.parse(json['date_rappel'] as String)
            : null,
        idVeterinaire: json['id_veterinaire'] as String?,
        lotVaccin: json['lot_vaccin'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'id_animal': idAnimal,
        'id_vaccin': idVaccin,
        'nom_vaccin': nomVaccin,
        'date_vaccination': dateVaccination.toIso8601String().split('T').first,
        'date_rappel': dateRappel?.toIso8601String().split('T').first,
        'id_veterinaire': idVeterinaire,
        'lot_vaccin': lotVaccin,
        'notes': notes,
      };

  /// Statut visuel basé sur date_rappel.
  VaccinationStatus get status {
    if (dateRappel == null) return VaccinationStatus.unknown;
    final now = DateTime.now();
    final diff = dateRappel!.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return VaccinationStatus.overdue;
    if (diff <= 30) return VaccinationStatus.soon;
    return VaccinationStatus.upToDate;
  }
}

enum VaccinationStatus { upToDate, soon, overdue, unknown }

/// Référentiel : entrée de la table `vaccin`.
class VaccinReference {
  final String id;
  final String nomVaccin;
  final String? typeAnimal;
  final String? description;
  final int? dureeValiditeMois;

  const VaccinReference({
    required this.id,
    required this.nomVaccin,
    this.typeAnimal,
    this.description,
    this.dureeValiditeMois,
  });

  factory VaccinReference.fromJson(Map<String, dynamic> json) => VaccinReference(
        id: json['id_vaccin'] as String,
        nomVaccin: json['nom_vaccin'] as String,
        typeAnimal: json['type_animal'] as String?,
        description: json['description'] as String?,
        dureeValiditeMois: json['duree_validite_mois'] as int?,
      );
}
