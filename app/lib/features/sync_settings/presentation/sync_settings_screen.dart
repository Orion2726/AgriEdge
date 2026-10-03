import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ml/crop_catalog.dart';
import '../../../core/ml/model_manager.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../../crop_recommendation/ml/crop_recommendation_model_manager.dart';
import '../../market_price/ml/price_forecast_model_manager.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  static const _domainLabels = {
    'market_price': 'Market prices',
    'msp': 'Minimum support price',
    'soil_report': 'Soil reports & crop recommendations',
    'disease_alerts': 'Nearby disease alerts',
    'detections': 'Disease detection uploads',
    'orders': 'Orders & catalog',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(syncManagerProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Data')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: isOnline ? Colors.green.shade50 : Colors.orange.shade50,
            child: ListTile(
              leading: Icon(isOnline ? Icons.wifi : Icons.wifi_off),
              title: Text(isOnline ? 'Online' : 'Offline'),
              subtitle: const Text('Background sync runs automatically when online.'),
              trailing: FilledButton(
                onPressed: isOnline ? () => manager.syncAll() : null,
                child: const Text('Sync all'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final domain in manager.domains) _SyncRow(domain: domain, label: _domainLabels[domain] ?? domain),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('Disease detection models', style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final crop in cropCatalog) _CropModelRow(crop: crop, isOnline: isOnline),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('Crop recommendation model', style: Theme.of(context).textTheme.titleSmall),
          ),
          _CropRecommendationModelRow(isOnline: isOnline),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('Price forecast model', style: Theme.of(context).textTheme.titleSmall),
          ),
          _PriceForecastModelRow(isOnline: isOnline),
        ],
      ),
    );
  }
}

class _SyncRow extends ConsumerWidget {
  const _SyncRow({required this.domain, required this.label});
  final String domain;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(syncManagerProvider);
    final lastSynced = ref.watch(domainLastSyncedProvider(domain));

    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          lastSynced.value == null
              ? 'Never synced'
              : 'Last synced ${DateFormat.yMMMd().add_jm().format(lastSynced.value!)}',
        ),
        trailing: OutlinedButton(
          onPressed: () async {
            await manager.syncDomain(domain);
            ref.invalidate(domainLastSyncedProvider(domain));
          },
          child: const Text('Sync now'),
        ),
      ),
    );
  }
}

class _CropModelRow extends ConsumerWidget {
  const _CropModelRow({required this.crop, required this.isOnline});
  final CropInfo crop;
  final bool isOnline;

  String _statusText(AsyncValue<ActiveModel> status) {
    return status.when(
      data: (model) {
        switch (model.source) {
          case ModelSource.downloaded:
            return 'Downloaded model, v${model.version}';
          case ModelSource.bundled:
            return 'Bundled model, v${model.version}';
          case ModelSource.none:
            return model.version == 'placeholder' ? 'Not trained yet' : 'No model installed';
        }
      },
      loading: () => 'Checking…',
      error: (e, _) => 'Could not check status: $e',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cropModelStatusProvider(crop.id));

    return Card(
      child: ListTile(
        leading: const Icon(Icons.download_for_offline_outlined),
        title: Text(crop.displayName),
        subtitle: Text(_statusText(status)),
        trailing: FilledButton.tonal(
          onPressed: isOnline
              ? () async {
                  try {
                    await ref.read(modelManagerProvider).downloadModel(crop.id);
                    ref.invalidate(cropModelStatusProvider(crop.id));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${crop.displayName} model updated.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
                    }
                  }
                }
              : null,
          child: const Text('Download'),
        ),
      ),
    );
  }
}

class _CropRecommendationModelRow extends ConsumerWidget {
  const _CropRecommendationModelRow({required this.isOnline});
  final bool isOnline;

  String _statusText(AsyncValue<ActiveCropRecModel> status) {
    return status.when(
      data: (model) {
        switch (model.source) {
          case CropRecModelSource.downloaded:
            return 'Downloaded model, v${model.version}';
          case CropRecModelSource.bundled:
            return 'Bundled model, v${model.version}';
          case CropRecModelSource.none:
            return model.version == 'placeholder' ? 'Not trained yet' : 'No model installed';
        }
      },
      loading: () => 'Checking…',
      error: (e, _) => 'Could not check status: $e',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(cropRecommendationModelStatusProvider);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.download_for_offline_outlined),
        title: const Text('Crop recommendation'),
        subtitle: Text(_statusText(status)),
        trailing: FilledButton.tonal(
          onPressed: isOnline
              ? () async {
                  try {
                    await ref.read(cropRecommendationModelManagerProvider).downloadModel();
                    ref.invalidate(cropRecommendationModelStatusProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Crop recommendation model updated.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
                    }
                  }
                }
              : null,
          child: const Text('Download'),
        ),
      ),
    );
  }
}

class _PriceForecastModelRow extends ConsumerWidget {
  const _PriceForecastModelRow({required this.isOnline});
  final bool isOnline;

  String _statusText(AsyncValue<ActivePriceForecastModel> status) {
    return status.when(
      data: (model) {
        switch (model.source) {
          case PriceForecastModelSource.downloaded:
            return 'Downloaded model, v${model.version}';
          case PriceForecastModelSource.bundled:
            return 'Bundled model, v${model.version}';
          case PriceForecastModelSource.none:
            return model.version == 'placeholder' ? 'Not trained yet' : 'No model installed';
        }
      },
      loading: () => 'Checking…',
      error: (e, _) => 'Could not check status: $e',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(priceForecastModelStatusProvider);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.download_for_offline_outlined),
        title: const Text('Price forecast'),
        subtitle: Text(_statusText(status)),
        trailing: FilledButton.tonal(
          onPressed: isOnline
              ? () async {
                  try {
                    await ref.read(priceForecastModelManagerProvider).downloadModel();
                    ref.invalidate(priceForecastModelStatusProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Price forecast model updated.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
                    }
                  }
                }
              : null,
          child: const Text('Download'),
        ),
      ),
    );
  }
}
