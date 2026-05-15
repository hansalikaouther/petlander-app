/// Modèle d'une mesure de croissance (table `historique_croissance`).
class GrowthRecord {
  final String id;
  final String idAnimal;
  final DateTime date;
  final double? poids;
  final double? taille;
  final double? indiceCorporel;
  final String? obs;
  final String? photoUrl;
  final DateTime? createdAt;

  const GrowthRecord({
    required this.id,
    required this.idAnimal,
    required this.date,
    this.poids,
    this.taille,
    this.indiceCorporel,
    this.obs,
    this.photoUrl,
    this.createdAt,
  });

  factory GrowthRecord.fromJson(Map<String, dynamic> json) => GrowthRecord(
        id: json['id'] as String,
        idAnimal: json['id_animal'] as String,
        date: DateTime.parse(json['date'] as String),
        poids: (json['poids'] as num?)?.toDouble(),
        taille: (json['taille'] as num?)?.toDouble(),
        indiceCorporel: (json['indice_corporel'] as num?)?.toDouble(),
        obs: json['obs'] as String?,
        photoUrl: json['photo_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() {
    final m = <String, dynamic>{
      'id_animal': idAnimal,
      'date': date.toIso8601String().split('T').first,
      'poids': poids,
      'taille': taille,
      'indice_corporel': indiceCorporel,
      'obs': obs,
    };
    if (photoUrl != null) m['photo_url'] = photoUrl;
    return m;
  }
}
