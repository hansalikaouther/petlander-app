/// Représentation de l'utilisateur Petlander (table `utilisateur`).
class AppUser {
  final String id;
  final String nom;
  final String email;
  final String? adresse;
  final String? numeroTelephone;
  final String? avatarUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.nom,
    required this.email,
    this.adresse,
    this.numeroTelephone,
    this.avatarUrl,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id_utilisateur'] as String,
        nom: json['nom'] as String? ?? '',
        email: json['email'] as String? ?? '',
        adresse: json['adresse'] as String?,
        numeroTelephone: json['numero_telephone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id_utilisateur': id,
        'nom': nom,
        'email': email,
        'adresse': adresse,
        'numero_telephone': numeroTelephone,
        'avatar_url': avatarUrl,
      };

  AppUser copyWith({
    String? nom,
    String? adresse,
    String? numeroTelephone,
    String? avatarUrl,
  }) =>
      AppUser(
        id: id,
        nom: nom ?? this.nom,
        email: email,
        adresse: adresse ?? this.adresse,
        numeroTelephone: numeroTelephone ?? this.numeroTelephone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}
