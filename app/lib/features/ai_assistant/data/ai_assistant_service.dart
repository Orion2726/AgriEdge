import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../domain/chat_message.dart';

/// Online: backend does a keyword-match "RAG" lookup against the same FAQ
/// content and (eventually) a real LLM — see backend/src/routes/assistant.js
/// and docs/MODEL_SPECS.md for where a real LLM API call slots in.
/// Offline: falls back to an on-device keyword match against the bundled
/// FAQ bank so the assistant degrades gracefully instead of breaking.
class AiAssistantService {
  AiAssistantService(this._dio, this._connectivity);

  final Dio _dio;
  final ConnectivityService _connectivity;
  final _uuid = const Uuid();
  List<Map<String, dynamic>>? _faqCache;

  Future<ChatMessage> ask(String query) async {
    if (_connectivity.isOnline) {
      try {
        final res = await _dio.post('/api/assistant/query', data: {'query': query});
        return ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          text: res.data['answer'] as String,
          timestamp: DateTime.now(),
          isOfflineFallback: false,
        );
      } catch (_) {
        // fall through to offline fallback below
      }
    }
    final answer = await _offlineFallback(query);
    return ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      text: answer,
      timestamp: DateTime.now(),
      isOfflineFallback: true,
    );
  }

  Future<List<Map<String, dynamic>>> _loadFaq() async {
    if (_faqCache != null) return _faqCache!;
    final raw = await rootBundle.loadString(AppConstants.offlineFaqAssetPath);
    _faqCache = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return _faqCache!;
  }

  Future<String> _offlineFallback(String query) async {
    final faq = await _loadFaq();
    final lowerQuery = query.toLowerCase();
    for (final entry in faq) {
      final keywords = (entry['keywords'] as List).cast<String>();
      if (keywords.any((k) => lowerQuery.contains(k.toLowerCase()))) {
        return entry['answer'] as String;
      }
    }
    return "I don't have an offline answer for that yet. Try asking about crop "
        "calendar, MSP, pests, fertilizer, irrigation, ordering, or your local "
        "Krishi Vigyan Kendra — or ask again once you're back online.";
  }
}

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService(ref.watch(apiClientProvider), ref.watch(connectivityServiceProvider));
});
