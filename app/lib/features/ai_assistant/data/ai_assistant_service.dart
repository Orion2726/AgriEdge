import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/live_feeds.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/p2p/relevance/farmer_profile.dart';
import '../../../core/p2p/store/p2p_packet_store.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/disease_label.dart';
import '../domain/chat_message.dart';

/// One retrievable fact with the source it came from.
class _Doc {
  _Doc(this.kind, this.text, this.source, String keywords) : tokens = _tokens('$keywords $text');
  final String kind; // price | msp | report | weather | treatment | calendar | faq | detection
  final String text;
  final String source;
  final Set<String> tokens;
}

const _stop = {
  'the', 'a', 'an', 'is', 'are', 'what', 'whats', 'of', 'for', 'in', 'on', 'my', 'me', 'i', 'to', 'and', 'any',
  'there', 'how', 'do', 'does', 'can', 'should', 'will', 'it', 'be', 'at', 'today', 'now', 'current', 'tell',
  'about', 'please', 'near', 'nearby', 'with', 'which', 'when', 'from', 'this', 'that', 'your', 'have',
};

/// Plain-word synonyms so "rate", "bhav" or "sick plant" find the right facts.
const _synonyms = {
  'rate': 'price', 'rates': 'price', 'prices': 'price', 'bhav': 'price', 'sell': 'price', 'selling': 'price',
  'cost': 'price', 'market': 'price', 'mandi': 'price',
  'support': 'msp', 'minimum': 'msp',
  'diseases': 'disease', 'sick': 'disease', 'infection': 'disease', 'pest': 'disease', 'pests': 'disease',
  'outbreak': 'disease', 'alert': 'disease', 'alerts': 'disease', 'reports': 'disease', 'report': 'disease',
  'cure': 'treat', 'treatment': 'treat', 'control': 'treat', 'spray': 'treat', 'medicine': 'treat',
  'rain': 'weather', 'raining': 'weather', 'rainfall': 'weather', 'forecast': 'weather', 'temperature': 'weather',
  'hot': 'weather', 'heat': 'weather', 'irrigate': 'weather', 'irrigation': 'weather',
  'sow': 'sowing', 'plant': 'sowing', 'planting': 'sowing', 'grow': 'sowing', 'harvest': 'sowing',
  'paddy': 'rice', 'maize': 'corn', 'blight': 'blight',
};

Set<String> _tokens(String text) {
  final words = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').split(RegExp(r'\s+'));
  final out = <String>{};
  for (var w in words) {
    if (w.length < 2 || _stop.contains(w)) continue;
    if (w.endsWith('s') && w.length > 4 && !_synonyms.containsKey(w)) w = w.substring(0, w.length - 1);
    out.add(w);
    final syn = _synonyms[w];
    if (syn != null) out.add(syn);
  }
  return out;
}

/// Farm assistant that answers from the information already on this phone —
/// synced prices and MSP, nearby disease reports, the weather forecast, the
/// bundled treatment guide, crop calendar and FAQ. Retrieval-only: it picks
/// the most relevant facts and quotes them with their source; it does not
/// generate free text with a language model (that would need a paid API key).
/// Works fully offline, with whatever data was last synced.
class AiAssistantService {
  AiAssistantService(this._ref);
  final Ref _ref;
  final _uuid = const Uuid();

  Future<ChatMessage> ask(String query) async {
    final q = _tokens(query);
    final docs = await _collect();
    final intents = {
      'price': q.contains('price'),
      'msp': q.contains('msp'),
      'report': q.contains('disease') && !q.contains('treat'),
      'weather': q.contains('weather'),
      'treatment': q.contains('treat') || q.contains('disease') || q.contains('blight'),
      'calendar': q.contains('sowing'),
    };

    final scored = <(_Doc, double)>[];
    for (final d in docs) {
      var s = q.intersection(d.tokens).length.toDouble();
      if (s == 0) continue;
      if (intents[d.kind] == true) s += 2;
      scored.add((d, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    // Keep only facts about the strongest topic(s), up to five.
    final top = scored.isEmpty ? 0.0 : scored.first.$2;
    final picked = scored.where((e) => e.$2 >= top - 1).take(5).map((e) => e.$1).toList();

    if (picked.isEmpty) {
      return _reply(
        "I couldn't find that in the information on this phone. Try asking about a crop price "
        '(e.g. "wheat price"), MSP, diseases reported nearby, the weather, how to treat a disease, '
        'or when to sow a crop.',
        const [],
      );
    }
    final lines = picked.map((d) => '• ${d.text}').join('\n');
    final sources = picked.map((d) => d.source).toSet().toList();
    return _reply(lines, sources);
  }

  ChatMessage _reply(String text, List<String> sources) => ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        text: text,
        timestamp: DateTime.now(),
        sources: sources,
      );

  Future<List<_Doc>> _collect() async {
    final db = _ref.read(appDatabaseProvider);
    final docs = <_Doc>[];
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final day = DateFormat.MMMd();

    // Prices & MSP (synced from the AgriEdge server — sample data).
    final synced = await _ref.read(syncManagerProvider).lastSyncedAt('market_price');
    final priceSource = 'Mandi prices (sample data${synced == null ? '' : ', synced ${day.format(synced)}'})';
    for (final p in await db.select(db.marketPrices).get()) {
      docs.add(_Doc('price',
          '${p.commodity}: ${money.format(p.pricePerQuintal)}/quintal at ${p.mandi} (price date ${day.format(p.priceDate)}).',
          priceSource, '${p.commodity} price'));
    }
    for (final m in await db.select(db.mspRates).get()) {
      docs.add(_Doc('msp', '${m.crop} MSP (${m.season} ${m.year}): ${money.format(m.pricePerQuintal)}/quintal.',
          'MSP table (sample data)', '${m.crop} msp price'));
    }

    // Disease reports: phone-to-phone and from the server.
    final mine = _ref.read(farmerProfileProvider).value?.myCropIds.toSet() ?? {};
    for (final r in await _ref.read(p2pPacketStoreProvider).allUnexpiredRows()) {
      final note = P2pPacketStore.payloadOf(r).note;
      docs.add(_Doc(
          'report',
          '${prettyDiseaseLabel(r.label)} on ${r.cropId.replaceAll('_', ' ')} reported ${day.add_jm().format(r.observedAt.toLocal())}'
              '${mine.contains(r.cropId) ? ' — a crop you grow' : ''}${note == null ? '' : ': "$note"'}',
          'Farmer reports from nearby phones',
          '${r.cropId} ${r.label} disease report'));
    }
    for (final a in await db.select(db.diseaseAlerts).get()) {
      docs.add(_Doc('report', '${prettyDiseaseLabel(a.label)}: ${a.detectionCount} reports within ${a.radiusKm.round()} km.',
          'Server disease clusters', '${a.label} disease report'));
    }
    for (final d in await (db.select(db.diseaseDetections)..limit(20)).get()) {
      docs.add(_Doc('detection', 'Your check on ${day.format(d.createdAt)}: ${prettyDiseaseLabel(d.label)} '
          '(${(d.confidence * 100).round()}% model confidence).', 'Your disease checks', '${d.cropId} ${d.label} disease'));
    }

    // Weather (last forecast fetched on this phone).
    try {
      final w = await _ref.read(weatherProvider.future);
      if (w != null) {
        final f = w.data.days.take(3).map((d) =>
            '${DateFormat.E().format(d.date)} ${d.maxC.round()}°/${d.minC.round()}°, rain chance ${d.rainChance}%').join('; ');
        docs.add(_Doc('weather', 'Now ${w.data.tempC.round()}°C, ${weatherLabel(w.data.code)}. Next days: $f.',
            'Open-Meteo forecast (${w.fromCache ? 'saved' : 'updated'} ${DateFormat.jm().format(w.fetchedAt)})', 'weather rain'));
        for (final tip in w.data.advice) {
          docs.add(_Doc('weather', tip, 'Open-Meteo forecast', 'weather rain spray irrigate'));
        }
      }
    } catch (_) {/* no forecast available offline yet */}

    // Bundled knowledge: treatments, crop calendar, FAQ.
    final treatments = jsonDecode(await rootBundle.loadString(AppConstants.treatmentsAssetPath)) as Map<String, dynamic>;
    treatments.forEach((crop, labels) {
      (labels as Map<String, dynamic>).forEach((label, v) {
        final t = v as Map<String, dynamic>;
        if ((t['disease'] as String).toLowerCase().contains('healthy')) return;
        docs.add(_Doc('treatment',
            '${t['disease']} (${t['crop']}): ${t['symptoms']} Treat: ${t['treatment']} Prevent: ${t['prevention']}',
            'AgriEdge treatment guide', '$crop $label ${t['disease']} treat disease'));
      });
    });
    for (final c in (jsonDecode(await rootBundle.loadString(AppConstants.cropCalendarAssetPath)) as List)) {
      docs.add(_Doc('calendar',
          '${c['crop']} (${c['season']}): sow ${c['sowingWindow']}, harvest ${c['harvestWindow']}.',
          'Crop calendar', '${c['crop']} sowing'));
    }
    for (final f in (jsonDecode(await rootBundle.loadString(AppConstants.offlineFaqAssetPath)) as List)) {
      docs.add(_Doc('faq', f['answer'] as String, 'Farming FAQ', '${(f['keywords'] as List).join(' ')} ${f['question']}'));
    }
    return docs;
  }
}

final aiAssistantServiceProvider = Provider<AiAssistantService>(AiAssistantService.new);
