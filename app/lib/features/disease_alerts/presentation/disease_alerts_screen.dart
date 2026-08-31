import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/disease_alerts_repository.dart';

class DiseaseAlertsScreen extends ConsumerWidget {
  const DiseaseAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(nearbyAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Disease Alerts')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(diseaseAlertsRepositoryProvider).refresh(),
        child: alerts.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No outbreak clusters reported nearby. Pull to refresh, or '
                      'this fills in as farmers around you report detections.',
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final alert = list[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                    title: Text(alert.label),
                    subtitle: Text(
                      '${alert.detectionCount} reports within ${alert.radiusKm.toStringAsFixed(0)} km · '
                      'since ${DateFormat.yMMMd().format(alert.windowStart)}',
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load cached alerts: $e')),
        ),
      ),
    );
  }
}
