/// Modèle Consultation (table `consultation`).
class Consultation {
  final String id;
  final String idAnimal;
  final String? idVeterinaire;
  final DateTime dateConsultation;
  final String? motif;
  final String? diagnostic;
  final String? observation;
  final double? poids;
  final double? taille;
  final double? temperature;
  final bool notification;
  final DateTime? createdAt;

  /// Joints (lecture seule)
  final String? veterinaireNom;
  final String? animalNom;

  const Consultation({
    required this.id,
    required this.idAnimal,
    this.idVeterinaire,
    required this.dateConsultation,
    this.motif,
    this.diagnostic,
    this.observation,
    this.poids,
    this.taille,
    this.temperature,
    this.notification = false,
    this.createdAt,
    this.veterinaireNom,
    this.animalNom,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    final vet = json['veterinaire'] as Map<String, dynamic>?;
    final animal = json['animal'] as Map<String, dynamic>?;
    return Consultation(
      id: json['id_consultation'] as String,
      idAnimal: json['id_animal'] as String,
      idVeterinaire: json['id_veterinaire'] as String?,
      dateConsultation: DateTime.parse(json['date_consultation'] as String),
      motif: json['motif'] as String?,
      diagnostic: json['diagnostic'] as String?,
      observation: json['observation'] as String?,
      poids: (json['poids'] as num?)?.toDouble(),
      taille: (json['taille'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      notification: json['notification'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      veterinaireNom: vet?['nom'] as String?,
      animalNom: animal?['nom'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'id_animal': idAnimal,
        'id_veterinaire': idVeterinaire,
        'date_consultation': dateConsultation.toIso8601String(),
        'motif': motif,
        'diagnostic': diagnostic,
        'observation': observation,
        'poids': poids,
        'taille': taille,
        'temperature': temperature,
        'notification': notification,
      };
}
