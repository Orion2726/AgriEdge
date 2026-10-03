import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/last_synced_label.dart';
import '../../msp/data/msp_repository.dart';
import '../data/market_price_repository.dart';
import '../domain/market_price_entry.dart';
import '../ml/price_forecast_ml_service.dart';

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
                    onTap: () => _showForecastSheet(context, ref, entry, currency),
                    title: Text(entry.commodity),
                    subtitle: Text('${entry.mandi} · ${DateFormat.yMMMd().format(entry.priceDate)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
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
                        const Icon(Icons.chevron_right, color: Colors.grey),
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

void _showForecastSheet(
  BuildContext context,
  WidgetRef ref,
  MarketPriceEntry entry,
  NumberFormat currency,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ForecastSheet(entry: entry, currency: currency, ref: ref),
  );
}

class _ForecastSheet extends StatelessWidget {
  const _ForecastSheet({required this.entry, required this.currency, required this.ref});

  final MarketPriceEntry entry;
  final NumberFormat currency;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final forecastFuture = ref.read(priceForecastMlServiceProvider).forecast(
          commodity: entry.commodity,
          todayPrice: entry.pricePerQuintal,
          asOf: DateTime.now(),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<DayForecast>?>(
          future: forecastFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final forecast = snapshot.data;
            if (forecast == null) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text('No forecast available for ${entry.commodity} yet.'),
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.commodity} — 7-day outlook', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Estimate based on seasonal patterns in historical mandi data — '
                  'treat the shaded range as the realistic outcome, not the single number.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < forecast.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(DateFormat.MMMd().format(DateTime.now().add(Duration(days: i + 1)))),
                        ),
                        Expanded(
                          child: Text(
                            '${currency.format(forecast[i].lowerBound)} – ${currency.format(forecast[i].upperBound)}',
                          ),
                        ),
                        Text(
                          '~${currency.format(forecast[i].price)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
