import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ml/crop_catalog.dart';
import '../../../core/ml/model_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/backend_config.dart';
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
    'p2p_alerts': 'Nearby-device alert uploads',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(syncManagerProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Sync & server')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: isOnline ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(isOnline ? Icons.wifi : Icons.wifi_off),
              title: Text(isOnline ? 'Online' : 'Offline'),
              subtitle: Text(isOnline
                  ? 'Data syncs with the AgriEdge server automatically.'
                  : 'Everything is saved on this phone and uploads when you are back online.'),
              trailing: FilledButton(
                onPressed: isOnline ? () => manager.syncAll() : null,
                child: const Text('Sync all'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _BackendServerCard(),
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
    final status = ref.watch(domainSyncStatusProvider(domain)).value;
    final theme = Theme.of(context);
    final syncing = status?.isSyncing ?? false;

    final lastSynced = status?.lastSyncedAt == null
        ? 'Never synced'
        : 'Last synced ${DateFormat.yMMMd().add_jm().format(status!.lastSyncedAt!)}';

    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(syncing ? 'Syncing…' : lastSynced),
            if (!syncing && status?.lastError != null)
              Text(
                'Last attempt failed: ${status!.lastError}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
          ],
        ),
        trailing: syncing
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton(
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

/// Where this phone's backend lives. Phones can't use the dev machine's
/// `localhost`; the farmer/tester enters its LAN address here.
class _BackendServerCard extends ConsumerStatefulWidget {
  const _BackendServerCard();

  @override
  ConsumerState<_BackendServerCard> createState() => _BackendServerCardState();
}

class _BackendServerCardState extends ConsumerState<_BackendServerCard> {
  final _controller = TextEditingController();
  String? _error;
  String? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(backendUrlProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      await ref.read(backendUrlProvider.notifier).set(_controller.text);
      final url = ref.read(backendUrlProvider);
      _controller.text = url;
      await createApiClient(url).get('/health');
      setState(() => _result = 'Connected to $url');
      ref.read(syncManagerProvider).syncAll(); // pull fresh data right away
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Saved, but the server did not answer: ${describeSyncError(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backendUrlProvider, (_, next) {
      if (_controller.text != next) _controller.text = next;
    });
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveAndTest(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: 'http://192.168.1.5:4001',
                errorText: _error,
                errorMaxLines: 3,
                helperText: _result,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _busy ? null : _saveAndTest,
                child: _busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save & test'),
              ),
            ),
          ],
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
