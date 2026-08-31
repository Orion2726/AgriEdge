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
      appBar: AppBar(title: const Text('Crop Recommendation')),
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
                    child: Text(
                      'No recommendation cached yet for your latest report — '
                      'this appears once you\'re back online and it syncs.',
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (context, index) => _SuggestionCard(suggestion: list[index]),
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final CropSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('#${suggestion.rank}')),
        title: Text(suggestion.cropName),
        subtitle: suggestion.nutrientAdvice.isEmpty
            ? null
            : Text(suggestion.nutrientAdvice.join('\n')),
        isThreeLine: suggestion.nutrientAdvice.isNotEmpty,
        trailing: Text('${(suggestion.suitabilityScore * 100).toStringAsFixed(0)}%'),
      ),
    );
  }
}
