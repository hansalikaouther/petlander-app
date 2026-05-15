/// Modèle Vétérinaire (table `veterinaire`).
class Veterinaire {
  final String id;
  final String? idUtilisateur;
  final String nom;
  final String? adresse;
  final String? numeroTelephone;
  final String? email;
  final String? specialite;
  final String? photoUrl;
  final DateTime? createdAt;

  const Veterinaire({
    required this.id,
    this.idUtilisateur,
    required this.nom,
    this.adresse,
    this.numeroTelephone,
    this.email,
    this.specialite,
    this.photoUrl,
    this.createdAt,
  });

  factory Veterinaire.fromJson(Map<String, dynamic> json) => Veterinaire(
        id: json['id_veterinaire'] as String,
        idUtilisateur: json['id_utilisateur'] as String?,
        nom: json['nom'] as String,
        adresse: json['adresse'] as String?,
        numeroTelephone: json['numero_telephone'] as String?,
        email: json['email'] as String?,
        specialite: json['specialite'] as String?,
        photoUrl: json['photo_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'id_utilisateur': idUtilisateur,
        'nom': nom,
        'adresse': adresse,
        'numero_telephone': numeroTelephone,
        'email': email,
        'specialite': specialite,
        'photo_url': photoUrl,
      };
}
