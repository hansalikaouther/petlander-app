/// Validateurs réutilisables pour les formulaires.
class Validators {
  Validators._();

  // ── Champs de texte ──────────────────────────────────────────────────────

  static String? required(String? v, {String label = 'Ce champ'}) {
    if (v == null || v.trim().isEmpty) return '$label est requis';
    return null;
  }

  /// Nom de personne ou d'animal : 2 à 60 caractères, lettres, espaces, tirets.
  static String? name(String? v, {String label = 'Le nom'}) {
    if (v == null || v.trim().isEmpty) return '$label est requis';
    final t = v.trim();
    if (t.length < 2) return '$label doit comporter au moins 2 caractères';
    if (t.length > 60) return '$label ne doit pas dépasser 60 caractères';
    if (!RegExp(r"^[a-zA-ZÀ-ÿ0-9\s\-']+$").hasMatch(t)) {
      return '$label contient des caractères non autorisés';
    }
    return null;
  }

  // ── Email ────────────────────────────────────────────────────────────────

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'L\'email est requis';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!regex.hasMatch(v.trim())) return 'Email invalide (ex : exemple@mail.com)';
    return null;
  }

  // ── Mot de passe ─────────────────────────────────────────────────────────

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est requis';
    if (v.length < 8) return 'Au moins 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Au moins 1 majuscule (A-Z)';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Au moins 1 minuscule (a-z)';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Au moins 1 chiffre (0-9)';
    return null;
  }

  /// Force du mot de passe : 0 = vide, 1 = faible … 4 = très fort.
  static int passwordStrength(String v) {
    if (v.isEmpty) return 0;
    var score = 0;
    if (v.length >= 8) score++;
    if (v.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]/\\]').hasMatch(v)) score++;
    return score.clamp(1, 4);
  }

  // ── Numéro de téléphone ───────────────────────────────────────────────────

  /// Accepte les formats :
  ///   - Algérie local  : 0XXXXXXXXX  (10 chiffres, commence par 05/06/07 ou 02/03/04)
  ///   - International  : +XXXXXXXXXXX (9 à 15 chiffres après le +)
  /// Les espaces et tirets sont ignorés lors de la validation.
  static String? phone(String? v) {
    if (v == null || v.isEmpty) return null; // champ optionnel
    final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Local algérien : 10 chiffres commençant par 0
    if (RegExp(r'^0[0-9]{9}$').hasMatch(cleaned)) return null;
    // International : + suivi de 9 à 15 chiffres
    if (RegExp(r'^\+[0-9]{9,15}$').hasMatch(cleaned)) return null;
    return 'Numéro invalide — ex : 05 12 34 56 78 ou +213 512 345 678';
  }

  /// Même règle que [phone] mais champ OBLIGATOIRE.
  static String? phoneRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le numéro de téléphone est requis';
    return phone(v);
  }

  // ── Numéro de puce électronique (ISO 11784 / 11785) ──────────────────────

  /// 15 chiffres (standard ISO microchip animal).
  static String? chipNumber(String? v) {
    if (v == null || v.isEmpty) return null; // optionnel
    final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\d{15}$').hasMatch(cleaned)) {
      return 'N° puce invalide — 15 chiffres requis (ex : 250269802500001)';
    }
    return null;
  }

  // ── Mesures ───────────────────────────────────────────────────────────────

  /// Poids en kg : nombre positif ≤ 500 kg.
  static String? weight(String? v) {
    if (v == null || v.isEmpty) return null; // optionnel
    final val = double.tryParse(v.replaceAll(',', '.'));
    if (val == null) return 'Poids invalide (ex : 4.5)';
    if (val <= 0) return 'Le poids doit être supérieur à 0';
    if (val > 500) return 'Poids trop élevé (max 500 kg)';
    return null;
  }

  /// Température en °C : intervalle 35–43 °C (mammifères).
  static String? temperature(String? v) {
    if (v == null || v.isEmpty) return null;
    final val = double.tryParse(v.replaceAll(',', '.'));
    if (val == null) return 'Température invalide (ex : 38.5)';
    if (val < 35 || val > 43) return 'Température hors plage (35 – 43 °C)';
    return null;
  }
}
