class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.sources = const [],
  });

  final String id;
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;

  /// Where the answer's facts came from (shown under the answer).
  final List<String> sources;
}
