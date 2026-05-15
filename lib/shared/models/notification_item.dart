/// Modèle Notification (table `notification`).
class NotificationItem {
  final String id;
  final String? idUtilisateur;
  final String? idRappel;
  final String titre;
  final String? contenu;
  final DateTime dateEnvoi;
  final bool lue;
  final String? type;

  const NotificationItem({
    required this.id,
    this.idUtilisateur,
    this.idRappel,
    required this.titre,
    this.contenu,
    required this.dateEnvoi,
    this.lue = false,
    this.type,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id_notification'] as String,
        idUtilisateur: json['id_utilisateur'] as String?,
        idRappel: json['id_rappel'] as String?,
        titre: json['titre'] as String,
        contenu: json['contenu'] as String?,
        dateEnvoi: DateTime.parse(json['date_envoi'] as String),
        lue: json['lue'] as bool? ?? false,
        type: json['type'] as String?,
      );
}
