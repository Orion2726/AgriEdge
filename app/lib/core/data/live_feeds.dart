import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../settings/farm_setup.dart';

/// Result of a live source: the data, when it was fetched, and whether it
/// came from the on-phone cache because the source couldn't be reached.
class Feed<T> {
  const Feed({required this.data, required this.fetchedAt, required this.fromCache, this.error, this.via});
  final T data;

  /// Set when the saved copy was received from a nearby phone, not fetched here.
  final String? via;
  final DateTime fetchedAt;
  final bool fromCache;
  final String? error;
}

final _feedDio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 8),
  receiveTimeout: const Duration(seconds: 10),
  headers: {'User-Agent': 'AgriEdge/1.0 (farmer demo app)'},
));

/// Fetch → cache, or fall back to the last good copy. One broken source never
/// breaks the screen.
Future<Feed<T>> _cached<T>(String key, Future<Object?> Function() fetch, T Function(Object?) parse) async {
  final prefs = await SharedPreferences.getInstance();
  // A fresher copy received from a nearby phone beats going to the network.
  final saved = prefs.getString(key);
  if (saved != null) {
    final m = jsonDecode(saved) as Map<String, dynamic>;
    final at = DateTime.parse(m['at'] as String);
    if (m['via'] != null && DateTime.now().difference(at) < const Duration(minutes: 30)) {
      return Feed(data: parse(m['raw']), fetchedAt: at, fromCache: true, via: m['via'] as String?);
    }
  }
  try {
    final raw = await fetch();
    final data = parse(raw);
    await prefs.setString(key, jsonEncode({'at': DateTime.now().toIso8601String(), 'raw': raw}));
    return Feed(data: data, fetchedAt: DateTime.now(), fromCache: false);
  } catch (e) {
    final cached = prefs.getString(key);
    if (cached == null) rethrow;
    final m = jsonDecode(cached) as Map<String, dynamic>;
    return Feed(
      data: parse(m['raw']),
      fetchedAt: DateTime.parse(m['at'] as String),
      fromCache: true,
      error: 'Offline — showing saved copy',
      via: m['via'] as String?,
    );
  }
}

// ---------------------------------------------------------------- weather

class DayForecast {
  const DayForecast(this.date, this.maxC, this.minC, this.rainMm, this.rainChance, this.code);
  final DateTime date;
  final double maxC, minC, rainMm;
  final int rainChance, code;
}

class Weather {
  const Weather({required this.tempC, required this.code, required this.days});
  final double tempC;
  final int code;
  final List<DayForecast> days;

  /// Plain-language advice from the next three days.
  List<String> get advice {
    final next = days.take(3).toList();
    final tips = <String>[];
    final wet = next.where((d) => d.rainChance >= 60 || d.rainMm >= 5).toList();
    if (wet.isNotEmpty) {
      tips.add('Rain likely ${_dayName(wet.first.date)} — hold off spraying and fertiliser before it.');
    } else {
      tips.add('Dry next 3 days — plan irrigation; good window for spraying.');
    }
    if (next.any((d) => d.maxC >= 38)) tips.add('Heat above 38 °C expected — irrigate early morning or evening.');
    return tips;
  }
}

String _dayName(DateTime d) {
  final today = DateTime.now();
  if (d.day == today.day) return 'today';
  if (d.difference(DateTime(today.year, today.month, today.day)).inDays == 1) return 'tomorrow';
  return 'on ${DateFormat.EEEE().format(d)}';
}

String weatherLabel(int code) => switch (code) {
      0 => 'Clear sky',
      1 || 2 => 'Partly cloudy',
      3 => 'Cloudy',
      45 || 48 => 'Fog',
      >= 51 && <= 57 => 'Drizzle',
      >= 61 && <= 67 => 'Rain',
      >= 80 && <= 82 => 'Rain showers',
      >= 95 => 'Thunderstorm',
      _ => 'Mixed',
    };

/// Open-Meteo: free, no API key (https://open-meteo.com, CC BY 4.0).
final weatherProvider = FutureProvider.autoDispose<Feed<Weather>?>((ref) async {
  final loc = ref.watch(farmSetupProvider.select((s) => s.location));
  if (loc == null) return null;
  return _cached<Weather>(
    weatherCacheKey(loc.lat, loc.lng),
    () async => (await _feedDio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
          'latitude': loc.lat,
          'longitude': loc.lng,
          'current': 'temperature_2m,weather_code',
          'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,weather_code',
          'timezone': 'auto',
          'forecast_days': 5,
        }))
            .data,
    (raw) {
      final m = raw as Map;
      final d = m['daily'] as Map;
      final days = <DayForecast>[];
      for (var i = 0; i < (d['time'] as List).length; i++) {
        days.add(DayForecast(
          DateTime.parse(d['time'][i] as String),
          (d['temperature_2m_max'][i] as num).toDouble(),
          (d['temperature_2m_min'][i] as num).toDouble(),
          ((d['precipitation_sum'][i] as num?) ?? 0).toDouble(),
          ((d['precipitation_probability_max'][i] as num?) ?? 0).toInt(),
          (d['weather_code'][i] as num).toInt(),
        ));
      }
      return Weather(
        tempC: (m['current']['temperature_2m'] as num).toDouble(),
        code: (m['current']['weather_code'] as num).toInt(),
        days: days,
      );
    },
  );
});

// ------------------------------------------------------------------- news

class NewsItem {
  const NewsItem({required this.title, required this.summary, required this.link, required this.source, this.published});
  final String title, summary, link, source;
  final DateTime? published;
}

/// Public RSS feeds, used as headline + short summary + link to the original.
const newsSources = {
  'Economic Times – Agriculture': 'https://economictimes.indiatimes.com/news/economy/agriculture/rssfeeds/1202099874.cms',
  'Krishi Jagran': 'https://krishijagran.com/feeds/rss',
};

final newsProvider = FutureProvider.autoDispose<Feed<List<NewsItem>>>((ref) async {
  return _cached<List<NewsItem>>(
    newsCacheKey,
    () async {
      final items = <NewsItem>[];
      Object? lastError;
      for (final e in newsSources.entries) {
        try {
          final xml = (await _feedDio.get<String>(e.value, options: Options(responseType: ResponseType.plain))).data!;
          items.addAll(_parseRss(xml, e.key));
        } catch (err) {
          lastError = err;
        }
      }
      if (items.isEmpty) throw lastError ?? StateError('no news source reachable');
      items.sort((a, b) => (b.published ?? DateTime(2000)).compareTo(a.published ?? DateTime(2000)));
      // Compact JSON (≈5 KB) so it can also be shared with nearby phones.
      return [
        for (final i in items.take(12))
          {'t': i.title, 's': i.summary, 'l': i.link, 'src': i.source, 'p': i.published?.toUtc().toIso8601String()}
      ];
    },
    (raw) => [
      for (final m in (raw as List).cast<Map>())
        NewsItem(
          title: m['t'] as String,
          summary: m['s'] as String,
          link: m['l'] as String,
          source: m['src'] as String,
          published: m['p'] == null ? null : DateTime.parse(m['p'] as String).toLocal(),
        )
    ],
  );
});

const newsCacheKey = 'feed_news_v2';
String weatherCacheKey(double lat, double lng) => 'feed_weather_${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}';

List<NewsItem> _parseRss(String xml, String source) {
  final doc = XmlDocument.parse(xml.trim().replaceFirst('\ufeff', ''));
  return [
    for (final it in doc.findAllElements('item').take(8))
      () {
        String t(String n) => it.getElement(n)?.innerText.trim() ?? '';
        final summary = t('description').replaceAll(RegExp(r'<[^>]*>'), '').trim();
        return NewsItem(
          title: t('title'),
          summary: summary.length > 160 ? '${summary.substring(0, 157)}…' : summary,
          link: t('link'),
          source: source,
          published: _parseRssDate(t('pubDate')),
        );
      }()
  ].where((i) => i.title.isNotEmpty && i.link.startsWith('http')).toList();
}

DateTime? _parseRssDate(String s) {
  try {
    return DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US').parse(s.trim(), true).toLocal();
  } catch (_) {
    try {
      // "Wed, 14 Oct 2026 14:28:49 +0530" — intl can't parse numeric zones.
      final m = RegExp(r'(\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([+-])(\d{2})(\d{2})').firstMatch(s);
      if (m == null) return null;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final utc = DateTime.utc(int.parse(m[3]!), months.indexOf(m[2]!) + 1, int.parse(m[1]!), int.parse(m[4]!),
          int.parse(m[5]!), int.parse(m[6]!));
      final offset = Duration(hours: int.parse(m[8]!), minutes: int.parse(m[9]!));
      return (m[7] == '+' ? utc.subtract(offset) : utc.add(offset)).toLocal();
    } catch (_) {
      return null;
    }
  }
}
