import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/last_synced_label.dart';
import '../data/msp_repository.dart';

class MspScreen extends ConsumerWidget {
  const MspScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(mspRatesProvider);
    final lastSynced = ref.watch(mspLastSyncedProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Minimum Support Price')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mspRepositoryProvider).refresh(),
        child: rates.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(child: Text('No MSP data yet. Pull to refresh.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: lastSynced.when(
                      data: (at) => LastSyncedLabel(lastSyncedAt: at),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  );
                }
                final entry = entries[index - 1];
                return Card(
                  child: ListTile(
                    title: Text(entry.crop),
                    subtitle: Text('${entry.season} ${entry.year}'),
                    trailing: Text(
                      '${currency.format(entry.pricePerQuintal)}/qtl',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load cached MSP: $e')),
        ),
      ),
    );
  }
}
