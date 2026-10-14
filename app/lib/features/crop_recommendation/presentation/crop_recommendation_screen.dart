import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../soil_report/data/soil_report_repository.dart';
import '../data/crop_recommendation_repository.dart';
import '../domain/crop_suggestion.dart';

class CropRecommendationScreen extends ConsumerWidget {
  const CropRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestReport = ref.watch(latestSoilReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('What should I grow?')),
      body: latestReport.when(
        data: (report) {
          if (report == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Submit a soil test report first to get crop recommendations.'),
              ),
            );
          }
          final suggestions = ref.watch(cropSuggestionsProvider(report.id));
          return suggestions.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No recommendation available for this report.'),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text('Based on your latest soil test', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  _BestCard(suggestion: list.first),
                  if (list.length > 1) ...[
                    const SizedBox(height: 16),
                    Text('Other options', style: Theme.of(context).textTheme.titleMedium),
                    for (final s in list.skip(1)) _SuggestionCard(suggestion: s),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load recommendations: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load soil report: $e')),
      ),
    );
  }
}

String _cropName(String raw) =>
    raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');

/// Model score in words — low scores are "possible", not a broken "0%".
String _fit(double score) => score >= 0.6
    ? 'Strong match'
    : score >= 0.25
        ? 'Good match'
        : score >= 0.05
            ? 'Possible'
            : 'Less suited';

class _BestCard extends StatelessWidget {
  const _BestCard({required this.suggestion});
  final CropSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Best choice', style: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.eco, color: scheme.onPrimaryContainer, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_cropName(suggestion.cropName),
                  style: text.headlineSmall?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
            ),
            Text(_fit(suggestion.suitabilityScore), style: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
          ]),
          for (final advice in suggestion.nutrientAdvice) ...[
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.tips_and_updates_outlined, size: 18, color: scheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(child: Text(advice, style: TextStyle(color: scheme.onPrimaryContainer))),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final CropSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${suggestion.rank}')),
        title: Text(_cropName(suggestion.cropName)),
        trailing: Text(_fit(suggestion.suitabilityScore), style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}
