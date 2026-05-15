/// Modèle Animal (table `animal`).
enum AnimalType {
  chien('chien', 'Chien'),
  chat('chat', 'Chat'),
  lapin('lapin', 'Lapin'),
  oiseau('oiseau', 'Oiseau'),
  rongeur('rongeur', 'Rongeur'),
  reptile('reptile', 'Reptile'),
  autre('autre', 'Autre');

  final String dbValue;
  final String label;
  const AnimalType(this.dbValue, this.label);

  static AnimalType fromDb(String? v) =>
      AnimalType.values.firstWhere((t) => t.dbValue == v, orElse: () => AnimalType.autre);
}

enum Sexe {
  male('M', 'Mâle'),
  femelle('F', 'Femelle'),
  inconnu('?', 'Inconnu');

  final String dbValue;
  final String label;
  const Sexe(this.dbValue, this.label);

  static Sexe fromDb(String? v) =>
      Sexe.values.firstWhere((s) => s.dbValue == v, orElse: () => Sexe.inconnu);
}

class Animal {
  final String id;
  final String idUtilisateur;
  final String nom;
  final AnimalType type;
  final String? race;
  final DateTime? dateNaissance;
  final Sexe sexe;
  final String? couleur;
  final double? poidsActuel;
  final String? photoUrl;
  final String? numeroPuce;
  final bool sterilise;
  final DateTime? createdAt;

  const Animal({
    required this.id,
    required this.idUtilisateur,
    required this.nom,
    required this.type,
    this.race,
    this.dateNaissance,
    this.sexe = Sexe.inconnu,
    this.couleur,
    this.poidsActuel,
    this.photoUrl,
    this.numeroPuce,
    this.sterilise = false,
    this.createdAt,
  });

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        id: json['id_animal'] as String,
        idUtilisateur: json['id_utilisateur'] as String,
        nom: json['nom'] as String,
        type: AnimalType.fromDb(json['type'] as String?),
        race: json['race'] as String?,
        dateNaissance: json['date_naissance'] != null
            ? DateTime.parse(json['date_naissance'] as String)
            : null,
        sexe: Sexe.fromDb(json['sexe'] as String?),
        couleur: json['couleur'] as String?,
        poidsActuel: (json['poids_actuel'] as num?)?.toDouble(),
        photoUrl: json['photo_url'] as String?,
        numeroPuce: json['numero_puce'] as String?,
        sterilise: json['sterilise'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'id_utilisateur': idUtilisateur,
        'nom': nom,
        'type': type.dbValue,
        'race': race,
        'date_naissance': dateNaissance?.toIso8601String().split('T').first,
        'sexe': sexe.dbValue,
        'couleur': couleur,
        'poids_actuel': poidsActuel,
        'photo_url': photoUrl,
        'numero_puce': numeroPuce,
        'sterilise': sterilise,
      };
}
