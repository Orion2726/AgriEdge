import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ml/model_manager.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/sync/sync_manager.dart';

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
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: const Text('Disease detection model'),
              subtitle: const Text('Download the latest trained model from the server.'),
              trailing: FilledButton.tonal(
                onPressed: isOnline
                    ? () async {
                        try {
                          await ref.read(modelManagerProvider).downloadLatestModel();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Model updated.')));
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
          ),
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
