class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isOfflineFallback = false,
  });

  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final bool isOfflineFallback;
}
