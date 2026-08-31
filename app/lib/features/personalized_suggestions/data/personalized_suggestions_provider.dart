import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../crop_recommendation/data/crop_recommendation_repository.dart';
import '../../disease_alerts/data/disease_alerts_repository.dart';
import '../../market_price/data/market_price_repository.dart';
import '../../msp/data/msp_repository.dart';
import '../../soil_report/data/soil_report_repository.dart';
import '../domain/suggestion.dart';

/// Deliberately not a trained model — this composes rules over data that's
/// already local (soil report, cached crop recommendation, price-vs-MSP,
/// nearby alerts, crop calendar), matching the "no separate model needed
/// for this pass" scope from the shell build-out.
final personalizedSuggestionsProvider = Provider<AsyncValue<List<Suggestion>>>((ref) {
  final soilReport = ref.watch(latestSoilReportProvider);
  final prices = ref.watch(marketPricesProvider);
  final msp = ref.watch(mspRatesProvider);
  final alerts = ref.watch(nearbyAlertsProvider);

  if (soilReport.isLoading || prices.isLoading || msp.isLoading || alerts.isLoading) {
    return const AsyncValue.loading();
  }

  final suggestions = <Suggestion>[];

  final report = soilReport.value;
  if (report != null) {
    final cropSuggestions = ref.watch(cropSuggestionsProvider(report.id)).value ?? [];
    for (final crop in cropSuggestions.take(1)) {
      for (final advice in crop.nutrientAdvice) {
        suggestions.add(Suggestion(
          title: 'From your soil report',
          description: advice,
          icon: Icons.grass,
        ));
      }
    }
  } else {
    suggestions.add(const Suggestion(
      title: 'Get crop recommendations',
      description: 'Submit a soil test report to unlock personalized crop and fertilizer advice.',
      icon: Icons.science_outlined,
    ));
  }

  final mspByCrop = {for (final m in msp.value ?? <dynamic>[]) m.crop: m};
  for (final price in prices.value ?? []) {
    final mspEntry = mspByCrop[price.commodity];
    if (mspEntry != null && price.pricePerQuintal >= mspEntry.pricePerQuintal * 1.05) {
      suggestions.add(Suggestion(
        title: '${price.commodity} price is up',
        description: 'Selling at ${price.mandi} is currently above MSP — a good time to sell.',
        icon: Icons.trending_up,
      ));
    }
  }

  for (final alert in (alerts.value ?? []).where((a) => a.detectionCount >= 3)) {
    suggestions.add(Suggestion(
      title: 'Disease risk nearby',
      description: '${alert.label.replaceAll('_', ' ')} reported ${alert.detectionCount} times near you. Inspect your crop.',
      icon: Icons.warning_amber_rounded,
    ));
  }

  return AsyncValue.data(suggestions);
});

/// Sowing-season nudges from the bundled crop calendar — loaded straight
/// from the asset (small, static, always-offline) rather than duplicated
/// into a Drift table.
final cropCalendarSuggestionsProvider = FutureProvider<List<Suggestion>>((ref) async {
  final raw = await rootBundle.loadString(AppConstants.cropCalendarAssetPath);
  final entries = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  final monthName = _monthName(DateTime.now().month);
  return entries
      .where((e) => (e['sowingWindow'] as String).toLowerCase().contains(monthName))
      .map((e) => Suggestion(
            title: 'Sowing window: ${e['crop']}',
            description: '${e['season']} sowing window is ${e['sowingWindow']}.',
            icon: Icons.calendar_month,
          ))
      .toList();
});

String _monthName(int month) {
  const names = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];
  return names[month - 1];
}
