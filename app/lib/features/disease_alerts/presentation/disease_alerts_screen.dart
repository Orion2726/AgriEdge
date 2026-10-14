import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/p2p/p2p_alert_service.dart';
import '../data/disease_alerts_repository.dart';
import '../domain/nearby_alert.dart';

/// The P2P mesh (§1 of docs/P2P_ALERT_PROTOCOL.md) runs as a foreground
/// session tied to this screen being open — not an always-on background
/// service. BLE background scanning is restricted on both platforms anyway
/// (see the plan doc's §1), and starting/stopping radio + location use
/// only while a farmer is actively looking at this screen is the more
/// honest, battery- and permission-respectful default until a real
/// multi-device pilot says otherwise.
class DiseaseAlertsScreen extends ConsumerStatefulWidget {
  const DiseaseAlertsScreen({super.key});

  @override
  ConsumerState<DiseaseAlertsScreen> createState() => _DiseaseAlertsScreenState();
}

class _DiseaseAlertsScreenState extends ConsumerState<DiseaseAlertsScreen> {
  bool _p2pStarting = false;
  bool _p2pActive = false;
  String? _p2pError;

  @override
  void initState() {
    super.initState();
    _startP2p();
  }

  Future<void> _startP2p() async {
    setState(() => _p2pStarting = true);
    try {
      final service = await ref.read(p2pAlertServiceFutureProvider.future);
      await service.start();
      if (!mounted) return;
      setState(() {
        _p2pActive = true;
        _p2pStarting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _p2pError = '$e';
        _p2pStarting = false;
      });
    }
  }

  @override
  void dispose() {
    // Fire-and-forget — the service tolerates being stopped after the
    // widget is gone, and awaiting here would need a BuildContext we no
    // longer have.
    if (_p2pActive) {
      ref.read(p2pAlertServiceFutureProvider.future).then((s) => s.stop());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkAlerts = ref.watch(nearbyAlertsProvider);
    final p2pAlerts = ref.watch(p2pAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Disease Alerts')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(diseaseAlertsRepositoryProvider).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _P2pStatusBanner(starting: _p2pStarting, active: _p2pActive, error: _p2pError),
            const SizedBox(height: 8),
            ...networkAlerts.when(
              data: (list) => list.map((a) => _AlertTile(alert: a)),
              loading: () => const [Center(child: CircularProgressIndicator())],
              error: (e, _) => [Text('Failed to load network alerts: $e')],
            ),
            ...p2pAlerts.when(
              data: (list) => list.map((a) => _AlertTile(alert: a)),
              loading: () => const [],
              error: (e, _) => [Text('Failed to load nearby-device alerts: $e')],
            ),
            if ((networkAlerts.value?.isEmpty ?? true) && (p2pAlerts.value?.isEmpty ?? true))
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No outbreak clusters reported nearby. Pull to refresh, or '
                  'this fills in as farmers around you report detections — '
                  'including over Bluetooth, with no internet needed.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _P2pStatusBanner extends StatelessWidget {
  const _P2pStatusBanner({required this.starting, required this.active, required this.error});
  final bool starting;
  final bool active;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Card(
        color: Colors.orange.shade50,
        child: ListTile(
          leading: const Icon(Icons.bluetooth_disabled),
          title: const Text('Nearby-device alerts unavailable'),
          subtitle: Text(error!),
        ),
      );
    }
    return Card(
      color: active ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: Icon(active ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
        title: Text(
          starting
              ? 'Starting nearby-device scanning…'
              : active
                  ? 'Listening for nearby farmers\' phones'
                  : 'Nearby-device scanning inactive',
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final NearbyAlert alert;

  @override
  Widget build(BuildContext context) {
    final viaP2p = alert.source == NearbyAlertSource.p2pNearby;
    return Card(
      child: ListTile(
        leading: Icon(
          viaP2p ? Icons.bluetooth : Icons.warning_amber_rounded,
          color: Colors.deepOrange,
        ),
        title: Text(alert.label),
        subtitle: Text(
          '${alert.detectionCount} reports within ${alert.radiusKm.toStringAsFixed(0)} km · '
          'since ${DateFormat.yMMMd().format(alert.windowStart)}'
          '${viaP2p ? ' · via nearby devices' : ''}',
        ),
      ),
    );
  }
}
