import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/animal.dart';
import '../data/chat_engine.dart';

/// État du chat : liste des messages + animal sélectionné (filtre).
class ChatState {
  final List<ChatMessage> messages;
  final AnimalType? selectedType;
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.selectedType,
    this.isTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    AnimalType? selectedType,
    bool? isTyping,
    bool clearType = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(messages: [ChatEngine.welcome()]);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(role: MessageRole.user, text: text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    // Petite latence simulée pour l'effet "l'IA réfléchit"
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final reply = ChatEngine.respond(text, animalType: state.selectedType);
    state = state.copyWith(
      messages: [...state.messages, reply],
      isTyping: false,
    );
  }

  void selectAnimalType(AnimalType? type) {
    state = state.copyWith(selectedType: type, clearType: type == null);
  }

  void reset() {
    state = ChatState(messages: [ChatEngine.welcome()]);
  }
}

final chatProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);
