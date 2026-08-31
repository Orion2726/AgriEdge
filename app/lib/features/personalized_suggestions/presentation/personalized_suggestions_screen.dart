import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personalized_suggestions_provider.dart';
import '../domain/suggestion.dart';

class PersonalizedSuggestionsScreen extends ConsumerWidget {
  const PersonalizedSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleBased = ref.watch(personalizedSuggestionsProvider);
    final seasonal = ref.watch(cropCalendarSuggestionsProvider);

    final all = <Suggestion>[
      ...ruleBased.value ?? [],
      ...seasonal.value ?? [],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('For You')),
      body: ruleBased.isLoading
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
              ? const Center(child: Text('No suggestions yet — check back after your first soil report.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: all.length,
                  itemBuilder: (context, index) {
                    final s = all[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(s.icon, color: Theme.of(context).colorScheme.primary),
                        title: Text(s.title),
                        subtitle: Text(s.description),
                      ),
                    );
                  },
                ),
    );
  }
}
