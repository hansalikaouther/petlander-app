/// Modèle Traitement (table `traitement`).
class Traitement {
  final String id;
  final String? idConsultation;
  final String idAnimal;
  final String? nomMedicament;
  final String? photoOrdoUrl;
  final String? dureeTraitement;
  final String? posologie;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? createdAt;

  const Traitement({
    required this.id,
    this.idConsultation,
    required this.idAnimal,
    this.nomMedicament,
    this.photoOrdoUrl,
    this.dureeTraitement,
    this.posologie,
    this.dateDebut,
    this.dateFin,
    this.createdAt,
  });

  factory Traitement.fromJson(Map<String, dynamic> json) => Traitement(
        id: json['id_traitement'] as String,
        idConsultation: json['id_consultation'] as String?,
        idAnimal: json['id_animal'] as String,
        nomMedicament: json['nom_medicament'] as String?,
        photoOrdoUrl: json['photo_ordo_url'] as String?,
        dureeTraitement: json['duree_traitement'] as String?,
        posologie: json['posologie'] as String?,
        dateDebut: json['date_debut'] != null
            ? DateTime.parse(json['date_debut'] as String)
            : null,
        dateFin: json['date_fin'] != null
            ? DateTime.parse(json['date_fin'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'id_consultation': idConsultation,
        'id_animal': idAnimal,
        'nom_medicament': nomMedicament,
        'photo_ordo_url': photoOrdoUrl,
        'duree_traitement': dureeTraitement,
        'posologie': posologie,
        'date_debut': dateDebut?.toIso8601String().split('T').first,
        'date_fin': dateFin?.toIso8601String().split('T').first,
      };

  /// Pourcentage d'avancement (0..1) basé sur date_debut et date_fin.
  double? get progressRatio {
    if (dateDebut == null || dateFin == null) return null;
    final total = dateFin!.difference(dateDebut!).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(dateDebut!).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool get isActive {
    final now = DateTime.now();
    final start = dateDebut ?? now;
    final end = dateFin ?? now;
    return !now.isBefore(start) && !now.isAfter(end);
  }
}
