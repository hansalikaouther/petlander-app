import '../../../shared/models/animal.dart';

/// Catégories de conseils quotidiens.
enum TipCategory {
  conseil('Conseil du jour', '💡'),
  nourriture('Nourriture & nutrition', '🥗'),
  sante('Santé & vaccins', '💉'),
  toilettage('Toilettage & hygiène', '🛁'),
  comportement('Comportement & jeu', '🎾'),
  protection('Protection & sécurité', '🛡️'),
  prevention('Prévention parasites & virus', '🦠');

  final String label;
  final String emoji;
  const TipCategory(this.label, this.emoji);
}

/// Un conseil quotidien (fonctionne pour 1 ou plusieurs types d'animaux).
class DailyTip {
  final String id;
  final String title;
  final String body;
  final TipCategory category;
  final List<AnimalType> applicableTo;

  const DailyTip({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.applicableTo,
  });
}

/// Base de données rule-based de conseils quotidiens vétérinaires.
/// ~50 conseils couvrant tous les types d'animaux.
class DailyTipsDatabase {
  DailyTipsDatabase._();

  static const _all = AnimalType.values;
  static const _mammals = [
    AnimalType.chien,
    AnimalType.chat,
    AnimalType.lapin,
    AnimalType.rongeur,
  ];
  static const _chienChat = [AnimalType.chien, AnimalType.chat];

  static const List<DailyTip> tips = [
    // ===== CHIEN =====
    DailyTip(
      id: 'd_chien_1',
      title: 'Promenade quotidienne',
      body: 'Un chien adulte a besoin de **30 à 60 minutes** de marche par jour minimum, selon sa race et son énergie. Les promenades stimulent son corps ET son esprit.',
      category: TipCategory.comportement,
      applicableTo: [AnimalType.chien],
    ),
    DailyTip(
      id: 'd_chien_2',
      title: 'Aliments TOXIQUES pour ton chien',
      body: '🚫 Évite absolument : **chocolat**, raisin, oignon, ail, avocat, xylitol (chewing-gums sans sucre), os cuits. Garde-les hors de portée !',
      category: TipCategory.nourriture,
      applicableTo: [AnimalType.chien],
    ),
    DailyTip(
      id: 'd_chien_3',
      title: 'Brossage des dents',
      body: 'Brosse les dents de ton chien **2 à 3 fois par semaine** avec un dentifrice spécial chien (jamais humain !). Cela prévient le tartre et les problèmes de gencives.',
      category: TipCategory.toilettage,
      applicableTo: [AnimalType.chien],
    ),
    DailyTip(
      id: 'd_chien_4',
      title: 'Coups de chaleur en été',
      body: '🌡️ Ne laisse JAMAIS ton chien dans une voiture, même 5 minutes. À 25°C dehors, l\'habitacle monte à 50°C en 20 min. Promène-le tôt le matin ou le soir.',
      category: TipCategory.protection,
      applicableTo: [AnimalType.chien],
    ),
    DailyTip(
      id: 'd_chien_5',
      title: 'Vermifuge régulier',
      body: 'Vermifuge ton chien tous les **3 mois** (chien adulte) ou tous les mois (chiot < 6 mois). Les parasites internes affectent sa santé sans signe visible.',
      category: TipCategory.prevention,
      applicableTo: [AnimalType.chien],
    ),
    DailyTip(
      id: 'd_chien_6',
      title: 'Socialisation du chiot',
      body: 'Entre **8 et 16 semaines** est la période clé : expose ton chiot à différentes personnes, sons, environnements. Cela évite les peurs et l\'agressivité plus tard.',
      category: TipCategory.comportement,
      applicableTo: [AnimalType.chien],
    ),

    // ===== CHAT =====
    DailyTip(
      id: 'd_chat_1',
      title: 'Hydratation du chat',
      body: 'Les chats boivent peu naturellement. Place **plusieurs gamelles d\'eau** dans la maison, ou installe une fontaine à eau (très efficace contre les problèmes urinaires).',
      category: TipCategory.nourriture,
      applicableTo: [AnimalType.chat],
    ),
    DailyTip(
      id: 'd_chat_2',
      title: 'Aliments DANGEREUX pour le chat',
      body: '🚫 Mortels : **lys** (toutes parties), **paracétamol/Doliprane**, oignon, ail, chocolat, raisin, lait pour adultes (intolérance lactose).',
      category: TipCategory.protection,
      applicableTo: [AnimalType.chat],
    ),
    DailyTip(
      id: 'd_chat_3',
      title: 'Bac à litière',
      body: '🧹 Règle d\'or : **1 bac par chat + 1 supplémentaire**. Nettoie chaque jour, change la litière 1×/semaine. Un chat propre ne fera pas ses besoins ailleurs.',
      category: TipCategory.toilettage,
      applicableTo: [AnimalType.chat],
    ),
    DailyTip(
      id: 'd_chat_4',
      title: 'Boules de poils',
      body: 'Brosse ton chat **2-3 fois/semaine** (quotidien pour les poils longs). Cela réduit les boules de poils ingérées qui peuvent provoquer vomissements et occlusions.',
      category: TipCategory.toilettage,
      applicableTo: [AnimalType.chat],
    ),
    DailyTip(
      id: 'd_chat_5',
      title: 'Stérilisation du chat',
      body: 'Stériliser ton chat (mâle ou femelle) **avant 6 mois** : moins de fugues, moins de bagarres, espérance de vie augmentée de 2-3 ans, prévention des cancers mammaires.',
      category: TipCategory.sante,
      applicableTo: [AnimalType.chat],
    ),
    DailyTip(
      id: 'd_chat_6',
      title: 'Griffoir indispensable',
      body: 'Place un griffoir vertical **stable et assez grand** près de ses zones de couchage. Ça évitera tes meubles et permet à ton chat de marquer son territoire.',
      category: TipCategory.comportement,
      applicableTo: [AnimalType.chat],
    ),

    // ===== LAPIN =====
    DailyTip(
      id: 'd_lapin_1',
      title: 'Foin à volonté',
      body: '🌾 Le foin doit représenter **80% de l\'alimentation** du lapin. Il use ses dents (qui poussent en continu) et fait fonctionner son transit. Sans foin = arrêt digestif possible.',
      category: TipCategory.nourriture,
      applicableTo: [AnimalType.lapin],
    ),
    DailyTip(
      id: 'd_lapin_2',
      title: 'Surveillance des selles',
      body: '⚠️ Un lapin **DOIT faire des crottes** toutes les heures. Si pas de crottes pendant 12h = URGENCE vétérinaire (stase digestive mortelle).',
      category: TipCategory.sante,
      applicableTo: [AnimalType.lapin],
    ),
    DailyTip(
      id: 'd_lapin_3',
      title: 'Vaccins essentiels',
      body: 'Vaccine ton lapin contre la **myxomatose** et le **VHD** chaque année. Ces 2 maladies sont mortelles à 100% et transmises par les insectes (même en intérieur).',
      category: TipCategory.sante,
      applicableTo: [AnimalType.lapin],
    ),
    DailyTip(
      id: 'd_lapin_4',
      title: 'Environnement adapté',
      body: 'Un lapin a besoin de **4h minimum hors de sa cage** par jour. Mieux : un grand enclos ou en liberté dans une pièce sécurisée (câbles cachés !).',
      category: TipCategory.protection,
      applicableTo: [AnimalType.lapin],
    ),

    // ===== OISEAU =====
    DailyTip(
      id: 'd_oiseau_1',
      title: 'Une cage suffisamment grande',
      body: 'La cage doit permettre à ton oiseau de **déployer ses ailes complètement**. Sortie hors cage quotidienne fortement recommandée.',
      category: TipCategory.protection,
      applicableTo: [AnimalType.oiseau],
    ),
    DailyTip(
      id: 'd_oiseau_2',
      title: 'Aliments TOXIQUES',
      body: '🚫 **Avocat = mortel** pour les oiseaux. Aussi : chocolat, oignon, sel, alcool, caféine, fruits à noyau (la chair est OK, le noyau toxique).',
      category: TipCategory.nourriture,
      applicableTo: [AnimalType.oiseau],
    ),
    DailyTip(
      id: 'd_oiseau_3',
      title: 'Attention aux courants d\'air',
      body: '🌬️ Les oiseaux sont **très fragiles aux courants d\'air**. Évite de placer la cage près d\'une fenêtre ouverte ou d\'un climatiseur. Et jamais de cuisine (vapeurs toxiques).',
      category: TipCategory.protection,
      applicableTo: [AnimalType.oiseau],
    ),
    DailyTip(
      id: 'd_oiseau_4',
      title: 'Plumes ébouriffées = alerte',
      body: '⚠️ Un oiseau qui reste **gonflé en boule** est probablement malade (ils cachent leurs symptômes). Consulte un vétérinaire NAC dans la journée.',
      category: TipCategory.sante,
      applicableTo: [AnimalType.oiseau],
    ),

    // ===== RONGEUR =====
    DailyTip(
      id: 'd_rongeur_1',
      title: 'Rongement obligatoire',
      body: 'Les dents des rongeurs poussent **en continu**. Fournis du bois non traité, branches de pommier ou poirier à ronger pour éviter la malocclusion dentaire.',
      category: TipCategory.sante,
      applicableTo: [AnimalType.rongeur],
    ),
    DailyTip(
      id: 'd_rongeur_2',
      title: 'Cochons d\'Inde et vitamine C',
      body: '🍊 Les cochons d\'Inde **ne synthétisent PAS** la vitamine C. Donne-leur poivron, persil, kiwi quotidiennement. Sinon : scorbut (mortel).',
      category: TipCategory.nourriture,
      applicableTo: [AnimalType.rongeur],
    ),
    DailyTip(
      id: 'd_rongeur_3',
      title: 'Hamster solitaire !',
      body: '⚠️ Le hamster syrien (le plus courant) est **strictement solitaire**. Mettre 2 ensemble = bagarres mortelles. 1 hamster = 1 cage.',
      category: TipCategory.comportement,
      applicableTo: [AnimalType.rongeur],
    ),

    // ===== REPTILE =====
    DailyTip(
      id: 'd_reptile_1',
      title: 'Lampe UVB indispensable',
      body: '☀️ Sans UVB, les reptiles diurnes ne synthétisent pas la vitamine D et **développent des malformations osseuses** (MBD). Change la lampe tous les 6 mois (les UV s\'éteignent avant la lumière).',
      category: TipCategory.sante,
      applicableTo: [AnimalType.reptile],
    ),
    DailyTip(
      id: 'd_reptile_2',
      title: 'Gradient de température',
      body: 'Les reptiles régulent leur T° en se déplaçant. Crée un **point chaud** (30-40°C) et un **point froid** (22-25°C) dans le terrarium. Vérifie au thermomètre.',
      category: TipCategory.protection,
      applicableTo: [AnimalType.reptile],
    ),
    DailyTip(
      id: 'd_reptile_3',
      title: 'Hygrométrie spécifique',
      body: '💧 Chaque espèce a son hygrométrie : pogona ~30%, gecko léopard ~40%, python royal ~60%, caméléon ~70%. Mauvaise hygrométrie = mues ratées + infections.',
      category: TipCategory.sante,
      applicableTo: [AnimalType.reptile],
    ),

    // ===== TOUS / GÉNÉRAUX =====
    DailyTip(
      id: 'd_all_1',
      title: 'Carnet de santé à jour',
      body: '📋 Mets à jour ta fiche Petlander à chaque consultation. Un historique complet aide ton véto à mieux soigner ton compagnon.',
      category: TipCategory.conseil,
      applicableTo: _all,
    ),
    DailyTip(
      id: 'd_all_2',
      title: 'Pesée mensuelle',
      body: '⚖️ Pèse ton animal **chaque mois** et note dans Petlander → Croissance. Une perte de poids inexpliquée est souvent le 1er signe de maladie.',
      category: TipCategory.sante,
      applicableTo: _mammals,
    ),
    DailyTip(
      id: 'd_all_3',
      title: 'Identification obligatoire',
      body: '🔖 Puce ou tatouage = obligatoire en Algérie pour chien et chat. C\'est ce qui te permet de retrouver ton animal s\'il fugue.',
      category: TipCategory.protection,
      applicableTo: _chienChat,
    ),
    DailyTip(
      id: 'd_all_4',
      title: 'Eau fraîche tous les jours',
      body: '💧 Change l\'eau de ton animal **chaque jour**, pas juste compléter. L\'eau stagnante développe des bactéries qui causent diarrhées et infections.',
      category: TipCategory.nourriture,
      applicableTo: _all,
    ),
    DailyTip(
      id: 'd_all_5',
      title: 'Visite annuelle',
      body: '🩺 Même en pleine forme, fais un **bilan annuel** chez le vétérinaire. Beaucoup de maladies sont silencieuses au début (rein, cœur, dents).',
      category: TipCategory.sante,
      applicableTo: _all,
    ),
    DailyTip(
      id: 'd_all_6',
      title: 'Anti-puces et anti-tiques',
      body: '🦠 Traite ton animal **toute l\'année**, pas seulement en été. Les puces résistent en intérieur l\'hiver. Pipettes ou comprimés selon prescription véto.',
      category: TipCategory.prevention,
      applicableTo: _mammals,
    ),
    DailyTip(
      id: 'd_all_7',
      title: 'Voyage en voiture',
      body: '🚗 Sécurise ton animal en voiture : caisse de transport (chat/petit chien), harnais ceinture (grand chien). Jamais en liberté = danger pour lui et toi.',
      category: TipCategory.protection,
      applicableTo: _mammals,
    ),
    DailyTip(
      id: 'd_all_8',
      title: 'Jeux et stimulation mentale',
      body: '🧩 Joue **15 min/jour** avec ton animal. Cela renforce votre lien et évite l\'ennui (cause #1 des comportements destructeurs).',
      category: TipCategory.comportement,
      applicableTo: _all,
    ),
    DailyTip(
      id: 'd_all_9',
      title: 'Adoptez, n\'achetez pas',
      body: '❤️ Refuges et associations regorgent d\'animaux qui attendent une famille. Pour ton prochain compagnon, pense adoption avant achat.',
      category: TipCategory.conseil,
      applicableTo: _all,
    ),
    DailyTip(
      id: 'd_all_10',
      title: 'Numéros d\'urgence',
      body: '📞 Garde le numéro de ton **vétérinaire de garde** dans tes contacts. En cas d\'urgence (accident, intoxication), chaque minute compte.',
      category: TipCategory.protection,
      applicableTo: _all,
    ),
  ];

  /// Retourne un conseil pour aujourd'hui basé sur les types d'animaux
  /// possédés par l'utilisateur. Le tip change chaque jour (déterministe).
  static DailyTip? tipForToday(List<AnimalType> userAnimals) {
    final applicable = tips.where((t) {
      if (userAnimals.isEmpty) return true;
      return t.applicableTo.any(userAnimals.contains);
    }).toList();
    if (applicable.isEmpty) return null;

    final dayOfYear = _dayOfYear(DateTime.now());
    return applicable[dayOfYear % applicable.length];
  }

  /// Retourne un conseil différent à chaque appel (basé sur l'heure au démarrage).
  static DailyTip? tipForLaunch(List<AnimalType> userAnimals) {
    final applicable = tips.where((t) {
      if (userAnimals.isEmpty) return true;
      return t.applicableTo.any(userAnimals.contains);
    }).toList();
    if (applicable.isEmpty) return null;

    // Seed = secondes depuis epoch → différent à chaque lancement
    final seed = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return applicable[seed % applicable.length];
  }

  static int _dayOfYear(DateTime d) {
    final start = DateTime(d.year);
    return d.difference(start).inDays;
  }
}
