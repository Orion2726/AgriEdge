import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/last_synced_label.dart';
import '../../../shared/widgets/ui.dart';
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
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/msp'),
            icon: const Icon(Icons.price_check),
            label: const Text('MSP'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(marketPriceRepositoryProvider).refresh(),
        child: prices.when(
          data: (entries) {
            if (entries.isEmpty) {
              return ListView(children: const [
                StateMessage(
                  icon: Icons.storefront_outlined,
                  text: 'No prices saved yet. Pull down to load them from the AgriEdge server.',
                ),
              ]);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SourceTag(
                          text: 'Sample prices from the AgriEdge demo server — not live mandi data',
                          warning: true,
                        ),
                        const SizedBox(height: 6),
                        lastSynced.when(
                          data: (at) => LastSyncedLabel(lastSyncedAt: at),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        Text('Tap a crop to see the 7-day price outlook.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
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
                  'treat the shaded range as the realistic outcome, not the line.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: _ForecastChart(
                    todayPrice: entry.pricePerQuintal,
                    forecast: forecast,
                    currency: currency,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    const Text('Estimate', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                    ),
                    const SizedBox(width: 6),
                    const Text('Typical range', style: TextStyle(fontSize: 12)),
                  ],
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

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({
    required this.todayPrice,
    required this.forecast,
    required this.currency,
  });

  final double todayPrice;
  final List<DayForecast> forecast;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final lowerSpots = [
      FlSpot(0, todayPrice),
      for (var i = 0; i < forecast.length; i++) FlSpot((i + 1).toDouble(), forecast[i].lowerBound),
    ];
    final upperSpots = [
      FlSpot(0, todayPrice),
      for (var i = 0; i < forecast.length; i++) FlSpot((i + 1).toDouble(), forecast[i].upperBound),
    ];
    final pointSpots = [
      FlSpot(0, todayPrice),
      for (var i = 0; i < forecast.length; i++) FlSpot((i + 1).toDouble(), forecast[i].price),
    ];

    final allValues = [
      todayPrice,
      ...forecast.map((f) => f.lowerBound),
      ...forecast.map((f) => f.upperBound),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.1 + 1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: forecast.length.toDouble(),
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                currency.format(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                final label = i == 0 ? 'Today' : DateFormat.Md().format(DateTime.now().add(Duration(days: i)));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              if (spot.barIndex != 2) return null; // only annotate the estimate line
              return LineTooltipItem(currency.format(spot.y), const TextStyle(color: Colors.white));
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: lowerSpots,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: upperSpots,
            color: Colors.transparent,
            barWidth: 0,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: pointSpots,
            color: primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
          ),
        ],
        betweenBarsData: [
          BetweenBarsData(fromIndex: 0, toIndex: 1, color: primary.withValues(alpha: 0.18)),
        ],
      ),
    );
  }
}
