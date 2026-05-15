/// Modèle Rendez-vous (table `rdv`).
enum AppointmentStatus {
  planifie('planifie', 'Planifié'),
  confirme('confirme', 'Confirmé'),
  passe('passe', 'Passé'),
  annule('annule', 'Annulé');

  final String dbValue;
  final String label;
  const AppointmentStatus(this.dbValue, this.label);

  static AppointmentStatus fromDb(String? v) => AppointmentStatus.values
      .firstWhere((s) => s.dbValue == v, orElse: () => AppointmentStatus.planifie);
}

class Appointment {
  final String id;
  final String idAnimal;
  final String? idUtilisateur;
  final String? idVeterinaire;
  final String? idConsultation;
  final DateTime dateHeure;
  final String? motif;
  final AppointmentStatus statut;
  final bool notification;
  final String? notes;
  final DateTime? createdAt;

  /// Champs joints (lecture uniquement) :
  final String? animalNom;
  final String? veterinaireNom;

  const Appointment({
    required this.id,
    required this.idAnimal,
    this.idUtilisateur,
    this.idVeterinaire,
    this.idConsultation,
    required this.dateHeure,
    this.motif,
    this.statut = AppointmentStatus.planifie,
    this.notification = true,
    this.notes,
    this.createdAt,
    this.animalNom,
    this.veterinaireNom,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final animalJoin = json['animal'] as Map<String, dynamic>?;
    final vetJoin = json['veterinaire'] as Map<String, dynamic>?;
    return Appointment(
      id: json['id_rdv'] as String,
      idAnimal: json['id_animal'] as String,
      idUtilisateur: json['id_utilisateur'] as String?,
      idVeterinaire: json['id_veterinaire'] as String?,
      idConsultation: json['id_consultation'] as String?,
      dateHeure: DateTime.parse(json['date_heure'] as String),
      motif: json['motif'] as String?,
      statut: AppointmentStatus.fromDb(json['statut'] as String?),
      notification: json['notification'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      animalNom: animalJoin?['nom'] as String?,
      veterinaireNom: vetJoin?['nom'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'id_animal': idAnimal,
        'id_utilisateur': idUtilisateur,
        'id_veterinaire': idVeterinaire,
        'id_consultation': idConsultation,
        'date_heure': dateHeure.toIso8601String(),
        'motif': motif,
        'statut': statut.dbValue,
        'notification': notification,
        'notes': notes,
      };

  bool get isPast => dateHeure.isBefore(DateTime.now());
  bool get isUpcoming => !isPast && statut != AppointmentStatus.annule;
}
