import '../../shared/models/animal.dart';

/// Suggestions de races par type d'animal (autocomplétion).
class BreedSuggestions {
  BreedSuggestions._();

  static const List<String> chien = [
    'Akita Inu',
    'Beagle',
    'Berger Allemand',
    'Berger Australien',
    'Berger Belge',
    'Bichon Frisé',
    'Bichon Maltais',
    'Border Collie',
    'Bouledogue Anglais',
    'Bouledogue Français',
    'Boxer',
    'Caniche',
    'Cavalier King Charles',
    'Chihuahua',
    'Cocker Spaniel',
    'Croisé / Bâtard',
    'Dalmatien',
    'Doberman',
    'Dogue Allemand',
    'Épagneul Breton',
    'Fox Terrier',
    'Golden Retriever',
    'Husky Sibérien',
    'Jack Russell',
    'Labrador',
    'Loulou de Poméranie',
    'Pinscher',
    'Pitbull',
    'Rottweiler',
    'Saint-Bernard',
    'Schnauzer',
    'Shar Pei',
    'Shiba Inu',
    'Shih Tzu',
    'Teckel',
    'Westie',
    'Yorkshire Terrier',
  ];

  static const List<String> chat = [
    'Abyssin',
    'American Shorthair',
    'Angora Turc',
    'Bengal',
    'Birman',
    'Bombay',
    'British Longhair',
    'British Shorthair',
    'Chartreux',
    'Cornish Rex',
    'Devon Rex',
    'Européen / Commun',
    'Exotic Shorthair',
    'Maine Coon',
    'Munchkin',
    'Norvégien',
    'Oriental',
    'Persan',
    'Ragdoll',
    'Russian Blue',
    'Sacré de Birmanie',
    'Savannah',
    'Scottish Fold',
    'Siamois',
    'Sibérien',
    'Sphynx',
    'Tonkinois',
  ];

  static const List<String> lapin = [
    'Angora',
    'Bélier',
    'Bélier Nain',
    'Géant des Flandres',
    'Hollandais',
    'Lapin Nain',
    'Néo-Zélandais',
    'Polonais',
    'Rex',
    'Tête de Lion',
  ];

  static const List<String> oiseau = [
    'Calopsitte',
    'Canari',
    'Cacatoès',
    'Cocktail',
    'Diamant Mandarin',
    'Inséparable',
    'Mainate',
    'Perroquet Amazone',
    'Perroquet Gris du Gabon',
    'Perruche Ondulée',
    'Pinson',
  ];

  static const List<String> rongeur = [
    'Chinchilla',
    'Cochon d\'Inde',
    'Furet',
    'Gerbille',
    'Hamster Roborovski',
    'Hamster Russe',
    'Hamster Syrien',
    'Octodon',
    'Rat',
    'Souris',
  ];

  static const List<String> reptile = [
    'Caméléon',
    'Dragon Barbu',
    'Gecko Léopard',
    'Iguane',
    'Pogona',
    'Python Royal',
    'Serpent des Blés',
    'Tortue de Floride',
    'Tortue de Terre',
    'Varan',
  ];

  static List<String> forType(AnimalType type) {
    switch (type) {
      case AnimalType.chien:
        return chien;
      case AnimalType.chat:
        return chat;
      case AnimalType.lapin:
        return lapin;
      case AnimalType.oiseau:
        return oiseau;
      case AnimalType.rongeur:
        return rongeur;
      case AnimalType.reptile:
        return reptile;
      case AnimalType.autre:
        return const [];
    }
  }
}
