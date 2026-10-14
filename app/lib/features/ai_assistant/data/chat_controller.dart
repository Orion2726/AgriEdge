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
          text: 'Ask me about crop prices, MSP, diseases reported near you, the weather, '
              'how to treat a disease, or when to sow. I answer from the information on this phone.',
          timestamp: DateTime.now(),
        ),
      ];

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    state = [
      ...state,
      ChatMessage(id: _uuid.v4(), role: 'user', text: text.trim(), timestamp: DateTime.now()),
    ];
    final reply = await ref.read(aiAssistantServiceProvider).ask(text.trim());
    state = [...state, reply];
  }
}

final chatControllerProvider = NotifierProvider<ChatController, List<ChatMessage>>(ChatController.new);
