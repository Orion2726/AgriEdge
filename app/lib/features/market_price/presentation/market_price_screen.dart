import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/last_synced_label.dart';
import '../../msp/data/msp_repository.dart';
import '../data/market_price_repository.dart';

class MarketPriceScreen extends ConsumerWidget {
  const MarketPriceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(marketPricesProvider);
    final mspRates = ref.watch(mspRatesProvider);
    final lastSynced = ref.watch(marketPriceLastSyncedProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Market Price')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketPriceRepositoryProvider).refresh(),
        child: prices.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(child: Text('No prices yet. Pull to refresh.'));
            }
            final mspByCrop = {
              for (final m in mspRates.value ?? []) m.crop: m,
            };
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
                final msp = mspByCrop[entry.commodity];
                final aboveMsp = msp != null && entry.pricePerQuintal >= msp.pricePerQuintal;
                return Card(
                  child: ListTile(
                    title: Text(entry.commodity),
                    subtitle: Text('${entry.mandi} · ${DateFormat.yMMMd().format(entry.priceDate)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currency.format(entry.pricePerQuintal)}/qtl',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (msp != null)
                          Text(
                            aboveMsp ? 'Above MSP' : 'Below MSP',
                            style: TextStyle(
                              fontSize: 11,
                              color: aboveMsp ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load cached prices: $e')),
        ),
      ),
    );
  }
}
