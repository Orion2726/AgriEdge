import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_message.dart';
import 'ai_assistant_service.dart';

class ChatController extends Notifier<List<ChatMessage>> {
  static const _uuid = Uuid();

  @override
  List<ChatMessage> build() => [
        ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          text: "Hi! I'm your farming assistant. Ask about crop calendars, pests, "
              "fertilizer, MSP, or irrigation.",
          timestamp: DateTime.now(),
        ),
      ];

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    state = [...state, userMessage];

    final reply = await ref.read(aiAssistantServiceProvider).ask(text.trim());
    state = [...state, reply];
  }
}

final chatControllerProvider = NotifierProvider<ChatController, List<ChatMessage>>(ChatController.new);
