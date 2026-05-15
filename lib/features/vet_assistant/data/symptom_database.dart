import '../../../shared/models/animal.dart';

/// Niveau d'urgence d'un symptôme.
enum UrgencyLevel {
  low('Faible', '🟢', 'Surveiller à la maison'),
  medium('Modérée', '🟡', 'Consulter dans les 24-48h'),
  high('Élevée', '🟠', 'Consulter rapidement (sous 24h)'),
  critical('CRITIQUE', '🔴', 'URGENCE : aller chez le véto immédiatement');

  final String label;
  final String emoji;
  final String advice;
  const UrgencyLevel(this.label, this.emoji, this.advice);
}

/// Représente un symptôme reconnaissable et ses informations cliniques.
class SymptomEntry {
  final String id;
  final String label;
  final List<String> keywords;
  final List<AnimalType> applicableTo;
  final UrgencyLevel urgency;
  final List<String> possibleCauses;
  final List<String> recommendations;
  final List<String> redFlags;

  const SymptomEntry({
    required this.id,
    required this.label,
    required this.keywords,
    required this.applicableTo,
    required this.urgency,
    required this.possibleCauses,
    required this.recommendations,
    this.redFlags = const [],
  });

  bool appliesTo(AnimalType type) => applicableTo.contains(type);

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    if (label.toLowerCase().contains(q)) return true;
    return keywords.any((k) => q.contains(k) || k.contains(q));
  }
}

/// Base de données vétérinaire de référence (rule-based).
/// Couvre les ~25 motifs de consultation les plus fréquents.
class SymptomDatabase {
  SymptomDatabase._();

  static const _all = AnimalType.values;
  static const _mammals = [
    AnimalType.chien,
    AnimalType.chat,
    AnimalType.lapin,
    AnimalType.rongeur,
  ];
  static const _chienChat = [AnimalType.chien, AnimalType.chat];

  static const List<SymptomEntry> entries = [
    // ===== DIGESTIF =====
    SymptomEntry(
      id: 'vomissements',
      label: 'Vomissements',
      keywords: ['vomi', 'vomit', 'régurgit', 'rejette', 'rend'],
      applicableTo: _all,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Indigestion ou changement alimentaire récent',
        'Ingestion d\'un corps étranger',
        'Boule de poils (chats)',
        'Gastrite ou intolérance alimentaire',
        'Parasite intestinal',
        'Intoxication (chocolat, raisin, oignon, plantes toxiques)',
      ],
      recommendations: [
        'Mettre à la diète 12-24h (eau seulement)',
        'Reprendre avec une alimentation très digeste (riz + poulet bouilli)',
        'Surveiller la fréquence et la présence de sang',
        'Vérifier qu\'il/elle boit suffisamment',
      ],
      redFlags: [
        'Vomissements répétés (>3 fois en 12h) → CRITIQUE',
        'Présence de sang ou de bile',
        'Animal abattu, déshydraté (peau qui ne reprend pas sa place)',
      ],
    ),

    SymptomEntry(
      id: 'diarrhee',
      label: 'Diarrhée',
      keywords: ['diarrhée', 'diarrhe', 'selles molles', 'liquide', 'colite'],
      applicableTo: _all,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Changement alimentaire brutal',
        'Stress (déménagement, nouvelle personne)',
        'Parasites intestinaux (giardia, vers)',
        'Infection virale ou bactérienne',
        'Allergie alimentaire',
      ],
      recommendations: [
        'Diète 12-24h puis alimentation très digeste',
        'Hydratation +++ (proposer eau ou bouillon de poulet)',
        'Vermifuge à jour ?',
      ],
      redFlags: [
        'Diarrhée hémorragique (sang) → CRITIQUE',
        'Plus de 48h sans amélioration',
        'Fièvre associée',
      ],
    ),

    SymptomEntry(
      id: 'perte_appetit',
      label: 'Perte d\'appétit',
      keywords: ['mange pas', 'mange plus', 'appétit', 'refuse', 'anorexie'],
      applicableTo: _all,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Stress ou changement d\'environnement',
        'Douleur dentaire ou buccale',
        'Maladie sous-jacente (rénale, hépatique)',
        'Période de chaleur',
        'Effet secondaire d\'un médicament',
      ],
      recommendations: [
        'Vérifier la bouche (gencives, dents)',
        'Proposer une nourriture appétente (humide, tiède)',
        'Surveiller la prise de boisson',
      ],
      redFlags: [
        'Plus de 24h sans manger chez le chat → URGENCE (lipidose hépatique)',
        'Plus de 48h chez le chien',
        'Associée à de la fièvre ou un abattement',
      ],
    ),

    // ===== RESPIRATOIRE =====
    SymptomEntry(
      id: 'toux',
      label: 'Toux',
      keywords: ['tousse', 'toux', 'racle', 'hk hk'],
      applicableTo: _chienChat,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Toux du chenil (Bordetella) — très contagieuse',
        'Cardiopathie (chez les vieux chiens)',
        'Bronchite chronique',
        'Corps étranger dans la gorge',
        'Asthme félin',
      ],
      recommendations: [
        'Éviter les colliers (passer au harnais)',
        'Maintenir l\'air humide',
        'Vaccin Toux du chenil à jour ?',
      ],
      redFlags: [
        'Difficultés respiratoires associées',
        'Coloration bleutée des gencives → URGENCE',
        'Fatigue intense',
      ],
    ),

    SymptomEntry(
      id: 'difficulte_respirer',
      label: 'Difficultés respiratoires',
      keywords: ['respire mal', 'essouffl', 'haletant', 'dyspnée', 'souffle'],
      applicableTo: _all,
      urgency: UrgencyLevel.critical,
      possibleCauses: [
        'Œdème pulmonaire (cardiaque)',
        'Pneumonie',
        'Coup de chaleur',
        'Choc anaphylactique',
        'Obstruction des voies aériennes',
      ],
      recommendations: [
        'CONSULTER IMMÉDIATEMENT',
        'Mettre l\'animal au calme et au frais',
        'Ne pas le contraindre',
      ],
      redFlags: [
        'Gencives bleutées ou pâles → URGENCE VITALE',
        'Bouche ouverte chez le chat = très grave',
      ],
    ),

    // ===== DERMATOLOGIE =====
    SymptomEntry(
      id: 'demangeaisons',
      label: 'Démangeaisons / Grattage',
      keywords: ['gratte', 'démangeaison', 'prurit', 'gratouill', 'mordille'],
      applicableTo: _mammals,
      urgency: UrgencyLevel.low,
      possibleCauses: [
        'Puces ou tiques',
        'Allergie cutanée (DAPP, alimentaire, environnement)',
        'Gale, teigne ou autre parasite',
        'Peau sèche',
        'Stress / TOC',
      ],
      recommendations: [
        'Vérifier la présence de puces (peigne anti-puces)',
        'Antiparasitaire à jour ?',
        'Bain à l\'avoine apaisant si peau irritée',
      ],
    ),

    SymptomEntry(
      id: 'perte_poils',
      label: 'Perte de poils anormale',
      keywords: ['perd poils', 'pelade', 'plaque', 'poil', 'alopécie'],
      applicableTo: _mammals,
      urgency: UrgencyLevel.low,
      possibleCauses: [
        'Mue saisonnière (normal si diffus)',
        'Allergie',
        'Teigne (zone arrondie sans poil)',
        'Déséquilibre hormonal',
        'Stress',
      ],
      recommendations: [
        'Brossage régulier',
        'Compléments oméga 3/6',
      ],
    ),

    // ===== URINAIRE =====
    SymptomEntry(
      id: 'urine_anormale',
      label: 'Problème urinaire',
      keywords: ['urine', 'pisse', 'urinaire', 'cystite', 'ne fait pas pipi'],
      applicableTo: _chienChat,
      urgency: UrgencyLevel.high,
      possibleCauses: [
        'Cystite (très fréquent chez le chat)',
        'Calculs urinaires',
        'Infection urinaire',
        'Insuffisance rénale (vieux chats)',
        'Diabète',
      ],
      recommendations: [
        'Stimuler la prise d\'eau (fontaine, alimentation humide)',
        'Surveiller la fréquence et la quantité',
      ],
      redFlags: [
        'Chat mâle qui ne peut plus uriner → URGENCE VITALE (obstruction)',
        'Sang dans l\'urine',
        'Cris en urinant',
      ],
    ),

    // ===== COMPORTEMENT =====
    SymptomEntry(
      id: 'lethargie',
      label: 'Léthargie / Abattement',
      keywords: ['fatigue', 'léthargi', 'abattu', 'mou', 'dort tout', 'ne bouge'],
      applicableTo: _all,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Infection ou fièvre',
        'Douleur (articulaire ou interne)',
        'Anémie',
        'Maladie chronique en évolution',
        'Dépression (séparation, deuil)',
      ],
      recommendations: [
        'Prendre la température (rectale, normale 38-39°C)',
        'Observer l\'appétit et la prise de boisson',
      ],
      redFlags: [
        'Refus total de bouger',
        'Gencives pâles',
        'Associé à des vomissements/diarrhée',
      ],
    ),

    SymptomEntry(
      id: 'agressivite',
      label: 'Changement de comportement / Agressivité',
      keywords: ['agressif', 'mord', 'grogne', 'changement comportement', 'irritable'],
      applicableTo: _mammals,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Douleur (le plus fréquent !)',
        'Peur ou stress',
        'Troubles hormonaux',
        'Sénilité',
      ],
      recommendations: [
        'Éviter les manipulations forcées',
        'Examen vétérinaire pour exclure une douleur',
      ],
    ),

    // ===== LOCOMOTEUR =====
    SymptomEntry(
      id: 'boiterie',
      label: 'Boiterie',
      keywords: ['boite', 'boiterie', 'patte', 'patte folle'],
      applicableTo: _mammals,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Entorse / contusion',
        'Corps étranger dans le coussinet',
        'Arthrose (chien âgé)',
        'Fracture',
        'Luxation rotule (petits chiens)',
      ],
      recommendations: [
        'Examiner la patte (épine, plaie)',
        'Repos strict 24h',
        'Pas de saut',
      ],
      redFlags: [
        'Patte qui pendouille → fracture probable',
        'Boiterie après une chute importante',
      ],
    ),

    // ===== GROSSESSE / REPRODUCTION =====
    SymptomEntry(
      id: 'pertes_vulvaires',
      label: 'Pertes vulvaires anormales',
      keywords: ['perte', 'vulve', 'sang', 'pyomètre'],
      applicableTo: _chienChat,
      urgency: UrgencyLevel.high,
      possibleCauses: [
        'Chaleurs (normal)',
        'Pyomètre (infection utérine, GRAVE)',
        'Métrite post-partum',
      ],
      recommendations: [
        'Si non stérilisée et pertes purulentes → CONSULTATION URGENTE',
      ],
      redFlags: [
        'Pertes purulentes + fièvre → URGENCE VITALE',
      ],
    ),

    // ===== YEUX / OREILLES =====
    SymptomEntry(
      id: 'yeux_rouges',
      label: 'Yeux rouges, larmoyants',
      keywords: ['yeux', 'larmoie', 'œil', 'conjonctivite', 'rouge'],
      applicableTo: _all,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Conjonctivite (allergique, infectieuse)',
        'Corps étranger (poil, poussière)',
        'Ulcère cornéen',
        'Glaucome',
      ],
      recommendations: [
        'Nettoyer doucement au sérum physiologique',
        'Empêcher l\'animal de se gratter (collerette)',
      ],
    ),

    SymptomEntry(
      id: 'oreille_rouge',
      label: 'Otite / Oreille douloureuse',
      keywords: ['oreille', 'secoue tête', 'gratte oreille', 'otite'],
      applicableTo: _chienChat,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Otite externe (fréquent chez les chiens à oreilles tombantes)',
        'Acariens (chez le chat)',
        'Corps étranger (épillet)',
        'Allergie',
      ],
      recommendations: [
        'Nettoyer avec solution auriculaire vétérinaire',
        'Ne JAMAIS utiliser de coton-tige profond',
      ],
    ),

    // ===== TEMPÉRATURE =====
    SymptomEntry(
      id: 'fievre',
      label: 'Fièvre',
      keywords: ['fièvre', 'chaud', 'température', 'fevre'],
      applicableTo: _all,
      urgency: UrgencyLevel.high,
      possibleCauses: [
        'Infection bactérienne ou virale',
        'Coup de chaleur',
        'Maladie inflammatoire',
        'Réaction vaccinale (24-48h post-vaccin = normal)',
      ],
      recommendations: [
        'Prendre la température rectale (normale 38-39°C)',
        'Mouiller pour rafraîchir si > 40°C',
        'CONSULTER si > 40°C ou plus de 24h',
      ],
    ),

    // ===== TOXIQUES =====
    SymptomEntry(
      id: 'intoxication',
      label: 'Intoxication suspectée',
      keywords: ['avalé', 'mangé chocolat', 'plante', 'poison', 'toxique', 'mort aux rats'],
      applicableTo: _all,
      urgency: UrgencyLevel.critical,
      possibleCauses: [
        'Chocolat, raisin, oignon, ail (chien/chat)',
        'Plantes toxiques (lys → mortel pour chat)',
        'Médicaments humains (paracétamol = mortel chat)',
        'Antigel, mort-aux-rats',
      ],
      recommendations: [
        'CONSULTER IMMÉDIATEMENT',
        'Apporter l\'emballage du produit ingéré',
        'Centre antipoison animal Algérie : 021 XX XX XX',
      ],
      redFlags: [
        'NE PAS faire vomir sans avis vétérinaire',
        'Ne pas donner de lait',
      ],
    ),

    // ===== SPÉCIFIQUE LAPIN / RONGEUR =====
    SymptomEntry(
      id: 'arret_transit_lapin',
      label: 'Arrêt du transit (lapin / rongeur)',
      keywords: ['ne mange pas', 'pas de crottes', 'transit'],
      applicableTo: [AnimalType.lapin, AnimalType.rongeur],
      urgency: UrgencyLevel.critical,
      possibleCauses: [
        'Stase digestive (URGENCE chez le lapin !)',
        'Trichobézoard (boule de poils)',
        'Stress',
      ],
      recommendations: [
        'CONSULTER en URGENCE — un lapin qui ne mange pas peut mourir en 24h',
        'Stimulation manuelle de l\'abdomen (massages doux)',
      ],
    ),

    // ===== SPÉCIFIQUE OISEAU =====
    SymptomEntry(
      id: 'oiseau_gonfle',
      label: 'Oiseau plumes ébouriffées',
      keywords: ['gonflé', 'ébouriffé', 'boule', 'inactif'],
      applicableTo: [AnimalType.oiseau],
      urgency: UrgencyLevel.high,
      possibleCauses: [
        'Maladie souvent avancée (les oiseaux cachent leurs symptômes)',
        'Hypothermie',
        'Infection respiratoire',
      ],
      recommendations: [
        'Réchauffer la cage (lampe à 30°C)',
        'CONSULTER vétérinaire NAC dans la journée',
      ],
    ),

    // ===== SPÉCIFIQUE REPTILE =====
    SymptomEntry(
      id: 'reptile_apathique',
      label: 'Reptile apathique / refuse de manger',
      keywords: ['refuse', 'mue', 'cache', 'apathie reptile'],
      applicableTo: [AnimalType.reptile],
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Température du terrarium inadaptée',
        'Mue en cours',
        'Hibernation naturelle (saison)',
        'Carence en UVB',
      ],
      recommendations: [
        'Vérifier T°/hygrométrie du terrarium',
        'Lampe UVB fonctionnelle ?',
      ],
    ),

    // ===== ROUTINE =====
    SymptomEntry(
      id: 'soif_excessive',
      label: 'Soif excessive (boit beaucoup)',
      keywords: ['boit beaucoup', 'soif', 'polydipsie'],
      applicableTo: _mammals,
      urgency: UrgencyLevel.medium,
      possibleCauses: [
        'Diabète sucré',
        'Insuffisance rénale',
        'Cushing (chien)',
        'Pyomètre (chienne non stérilisée)',
        'Forte chaleur (normal)',
      ],
      recommendations: [
        'Quantifier sur 24h (normale chien : 50-90 ml/kg/j)',
        'Bilan sanguin recommandé',
      ],
    ),
  ];

  /// Trouve les symptômes correspondant au texte saisi par l'utilisateur,
  /// filtrés par type d'animal sélectionné.
  static List<SymptomEntry> match(String query, AnimalType? type) {
    if (query.trim().isEmpty) return const [];
    final results = entries.where((e) {
      if (type != null && !e.appliesTo(type)) return false;
      return e.matchesQuery(query);
    }).toList();
    // Trie : urgence critique en premier
    results.sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
    return results;
  }

  /// Tous les symptômes applicables à un type d'animal.
  static List<SymptomEntry> forType(AnimalType type) =>
      entries.where((e) => e.appliesTo(type)).toList();
}
