import '../../../shared/models/animal.dart';
import 'symptom_database.dart';

/// Type d'un message dans la conversation.
enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final List<SymptomEntry>? matchedSymptoms;
  final UrgencyLevel? urgency;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.matchedSymptoms,
    this.urgency,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Moteur conversationnel local (rule-based) pour le Vet Assistant.
/// Simule un mini-chatbot capable d'analyser des symptômes et de donner
/// des conseils préliminaires + niveau d'urgence.
///
/// L'architecture est conçue pour pouvoir brancher facilement une vraie IA
/// (Claude API ou OpenAI) en remplaçant uniquement la méthode [respond].
class ChatEngine {
  static const String _disclaimer =
      '*Important : Je ne remplace PAS un vétérinaire. '
      'Mes conseils sont indicatifs. En cas de doute, consulte un professionnel.*';

  static const _greetings = [
    'Bonjour 👋 Je suis l\'Assistant Vet de Petlander.',
    'Décris-moi les symptômes de ton compagnon en quelques mots.',
    'Exemples : "mon chien vomit depuis ce matin" ou "mon chat se gratte beaucoup".',
  ];

  static ChatMessage welcome() {
    return ChatMessage(
      role: MessageRole.assistant,
      text: '${_greetings.join('\n\n')}\n\n$_disclaimer',
    );
  }

  /// Analyse un message utilisateur et génère une réponse.
  /// [animalType] permet de filtrer les symptômes pertinents.
  static ChatMessage respond(String userMessage, {AnimalType? animalType}) {
    final clean = userMessage.trim().toLowerCase();

    // Salutations
    if (_isGreeting(clean)) {
      return ChatMessage(
        role: MessageRole.assistant,
        text: 'Bonjour ! Comment puis-je aider ton compagnon aujourd\'hui ? '
            'Décris-moi ses symptômes (ex: vomissements, perte d\'appétit, '
            'difficultés à respirer...).',
      );
    }

    // Remerciements
    if (_isThanks(clean)) {
      return ChatMessage(
        role: MessageRole.assistant,
        text: 'De rien ! Prends soin de ton compagnon.\n\n'
            'N\'oublie pas : si les symptômes s\'aggravent ou persistent au-delà '
            'de 24-48h, consulte un vétérinaire.',
      );
    }

    // Questions générales sur l'app
    if (clean.contains('rappel') || clean.contains('vaccin')) {
      return ChatMessage(
        role: MessageRole.assistant,
        text: 'Pour gérer les rappels de vaccins, va dans la fiche de ton animal '
            '→ "Vaccinations" → "Ajouter". Petlander te notifiera 7 jours avant '
            'la date de rappel automatiquement 📅',
      );
    }

    // Recherche de symptômes
    final matches = SymptomDatabase.match(clean, animalType);

    if (matches.isEmpty) {
      return ChatMessage(
        role: MessageRole.assistant,
        text: 'Je n\'ai pas identifié de symptôme précis dans ton message. '
            'Peux-tu reformuler en utilisant des mots-clés simples ?\n\n'
            'Exemples :\n'
            '• "vomissements"\n'
            '• "diarrhée"\n'
            '• "ne mange plus"\n'
            '• "boite"\n'
            '• "yeux rouges"\n'
            '• "se gratte"\n\n'
            'Tu peux aussi consulter la liste complète des symptômes en bas.',
      );
    }

    // Construit la réponse à partir du symptôme le plus urgent
    final topMatch = matches.first;
    final reply = _formatResponse(topMatch, otherMatches: matches.skip(1).toList());

    return ChatMessage(
      role: MessageRole.assistant,
      text: reply,
      matchedSymptoms: matches,
      urgency: topMatch.urgency,
    );
  }

  static String _formatResponse(SymptomEntry s, {List<SymptomEntry> otherMatches = const []}) {
    final buf = StringBuffer();

    // En-tête avec urgence
    buf.writeln('${s.urgency.emoji} **${s.label}** — Urgence : ${s.urgency.label}');
    buf.writeln('_${s.urgency.advice}_');
    buf.writeln();

    // Causes possibles
    buf.writeln('**Causes possibles :**');
    for (final c in s.possibleCauses) {
      buf.writeln('• $c');
    }
    buf.writeln();

    // Recommandations
    buf.writeln('**Que faire :**');
    for (final r in s.recommendations) {
      buf.writeln('✓ $r');
    }

    // Red flags
    if (s.redFlags.isNotEmpty) {
      buf.writeln();
      buf.writeln('**Signaux d\'alerte (consulter immédiatement) :**');
      for (final f in s.redFlags) {
        buf.writeln('- $f');
      }
    }

    // Suggérer les autres symptômes proches
    if (otherMatches.isNotEmpty) {
      buf.writeln();
      buf.writeln('Suggestions : '
          '${otherMatches.take(3).map((e) => e.label).join(', ')}.');
    }

    buf.writeln();
    buf.writeln('---');
    buf.writeln(_disclaimer);

    return buf.toString();
  }

  static bool _isGreeting(String s) {
    const g = ['bonjour', 'salut', 'hello', 'hi ', 'coucou', 'hey'];
    return g.any((k) => s.startsWith(k) || s == k.trim());
  }

  static bool _isThanks(String s) {
    const t = ['merci', 'thanks', 'thx', 'super', 'parfait'];
    return t.any((k) => s.contains(k));
  }
}
