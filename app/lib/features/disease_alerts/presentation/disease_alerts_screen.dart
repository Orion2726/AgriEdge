import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ml/crop_catalog.dart';
import '../../../core/p2p/p2p_alert_service.dart';
import '../../../core/p2p/relevance/farmer_profile.dart';
import '../../../core/p2p/security/device_identity.dart';
import '../../../core/p2p/store/p2p_packet_store.dart';
import '../../../core/p2p/transport/p2p_transport.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/disease_label.dart';
import '../data/disease_alerts_repository.dart';
import '../domain/nearby_alert.dart';

/// Point-in-time view of the nearby-device (BLE) session for the UI.
class P2pSessionSnapshot {
  const P2pSessionSnapshot({
    required this.state,
    required this.detail,
    required this.peers,
    required this.localDeviceId,
  });

  final P2pTransportState state;
  final String? detail;
  final List<PeerStatus> peers;
  final String localDeviceId;
}

/// Re-emits on every transport status change, plus a slow tick so relative
/// times ("seen 12 s ago") don't go stale on screen.
final p2pSessionSnapshotProvider = StreamProvider.autoDispose<P2pSessionSnapshot>((ref) async* {
  final service = await ref.watch(p2pAlertServiceFutureProvider.future);
  final manager = service.transportManager;
  P2pSessionSnapshot snapshot() => P2pSessionSnapshot(
        state: manager.state,
        detail: manager.stateDetail,
        peers: manager.peers,
        localDeviceId: service.localDeviceId,
      );
  final ticks = StreamController<void>();
  final statusSub = manager.statusChanged.listen(ticks.add);
  final timer = Timer.periodic(const Duration(seconds: 5), (_) => ticks.add(null));
  ref.onDispose(() {
    statusSub.cancel();
    timer.cancel();
    ticks.close();
  });
  yield snapshot();
  await for (final _ in ticks.stream) {
    yield snapshot();
  }
});

/// Every unexpired alert in this phone's P2P cache — its own and ones
/// received from nearby phones — so a single report is visible even before
/// enough reports exist to form a cluster.
final p2pReportsProvider = StreamProvider.autoDispose<List<P2pPacket>>((ref) {
  return ref.watch(p2pPacketStoreProvider).watchRecent();
});

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
  P2pAlertService? _service;
  String? _networkError;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _startP2p();
    _refreshNetworkAlerts(askPermission: true);
  }

  Future<void> _startP2p() async {
    try {
      final P2pAlertService service =
          _service ?? await ref.read(p2pAlertServiceFutureProvider.future);
      _service = service;
      await service.stop(); // no-op unless retrying after a failed start
      await service.start();
    } catch (_) {
      // The status card shows the transport's own explanation (permission
      // denied, Bluetooth off, …) with a retry action.
    }
  }

  Future<void> _refreshNetworkAlerts({bool askPermission = false}) async {
    final repo = ref.read(diseaseAlertsRepositoryProvider);
    setState(() => _refreshing = true);
    try {
      if (askPermission) await repo.requestLocationPermission();
      await repo.refresh();
      if (mounted) setState(() => _networkError = null);
    } catch (e) {
      if (mounted) {
        setState(() => _networkError = e is LocationUnavailableException ? e.message : describeSyncError(e));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  void dispose() {
    // Fire-and-forget — the service tolerates being stopped after the
    // widget is gone, and awaiting here would need a BuildContext we no
    // longer have.
    _service?.stop();
    super.dispose();
  }

  Future<void> _sendDebugTestAlert() async {
    final service = _service;
    if (service == null) return;
    // Debug builds only: originates a real signed packet through the same
    // broadcastDetection() path a saved detection uses, so two-phone tests
    // can generate distinct, identifiable alerts without a camera.
    double lat = 12.8406, lng = 80.1534; // fixed test site if no fix
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}
    final stamp = DateFormat('HHmmss').format(DateTime.now());
    final packet = await service.broadcastDetection(
      cropId: 'potato',
      label: 'Potato___Late_blight',
      confidence: 0.9,
      severity: 'high',
      lat: lat,
      lng: lng,
      detectionId: 'debug-${service.localDeviceId}-$stamp',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test alert ${packet.packetIdHex.substring(0, 8)} created')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkAlerts = ref.watch(nearbyAlertsProvider);
    final p2pClusters = ref.watch(p2pAlertsProvider);
    final reports = ref.watch(p2pReportsProvider);
    final session = ref.watch(p2pSessionSnapshotProvider);

    final hasAnything = (networkAlerts.value?.isNotEmpty ?? false) ||
        (p2pClusters.value?.isNotEmpty ?? false) ||
        (reports.value?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Disease Alerts'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Send test alert (debug)',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: _sendDebugTestAlert,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshNetworkAlerts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _P2pStatusCard(session: session, onRetry: _startP2p),
              const SizedBox(height: 8),
              const _MyCropsCard(),
              if (_networkError != null)
                _InlineNotice(
                  icon: Icons.cloud_off,
                  text: 'Online alerts: $_networkError',
                  action: _refreshing ? null : TextButton(onPressed: _refreshNetworkAlerts, child: const Text('Retry')),
                ),
              if (_refreshing) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
              ..._section(
                context,
                'Outbreak clusters',
                [
                  ...networkAlerts.value?.map((a) => _AlertTile(alert: a)) ?? const <Widget>[],
                  ...p2pClusters.value?.map((a) => _AlertTile(alert: a)) ?? const <Widget>[],
                ],
              ),
              ..._section(
                context,
                'Reports shared between phones',
                [
                  for (final row in reports.value ?? const <P2pPacket>[])
                    _ReportTile(row: row, localDeviceId: session.value?.localDeviceId),
                ],
              ),
              if (!hasAnything && !networkAlerts.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  child: Text(
                    'No disease reports nearby yet. This fills in as farmers around you '
                    'share detections — over the internet, or phone-to-phone over Bluetooth '
                    'with no internet needed.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _section(BuildContext context, String title, List<Widget> children) {
    if (children.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      ...children,
    ];
  }
}

class _P2pStatusCard extends StatelessWidget {
  const _P2pStatusCard({required this.session, required this.onRetry});
  final AsyncValue<P2pSessionSnapshot> session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snap = session.value;
    final state = snap?.state ?? P2pTransportState.starting;

    final (IconData icon, String title, bool problem) = switch (state) {
      P2pTransportState.running => (
          Icons.bluetooth_searching,
          snap!.peers.isEmpty
              ? 'Looking for nearby AgriEdge phones…'
              : '${snap.peers.length} nearby phone${snap.peers.length == 1 ? '' : 's'} in range',
          false
        ),
      P2pTransportState.starting || P2pTransportState.stopped => (
          Icons.bluetooth,
          'Starting nearby-device sharing…',
          false
        ),
      P2pTransportState.bluetoothOff => (Icons.bluetooth_disabled, 'Bluetooth is off', true),
      P2pTransportState.permissionDenied => (Icons.block, 'Nearby-devices permission needed', true),
      P2pTransportState.unsupported => (Icons.bluetooth_disabled, 'Not supported on this phone', true),
      P2pTransportState.failed => (Icons.error_outline, 'Nearby-device sharing stopped', true),
    };

    final background = problem ? scheme.errorContainer : scheme.secondaryContainer;
    final foreground = problem ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (state == P2pTransportState.starting)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                  )
                else
                  Icon(icon, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: foreground)),
                ),
                if (problem && state != P2pTransportState.unsupported)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(foregroundColor: foreground),
                    child: const Text('Try again'),
                  ),
              ],
            ),
            if (problem && snap?.detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(snap!.detail!, style: TextStyle(color: foreground)),
              ),
            if (state == P2pTransportState.running && snap!.peers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Keep this screen open on both phones. Alerts are exchanged automatically '
                  'when another phone with AgriEdge is within Bluetooth range.',
                  style: TextStyle(color: foreground),
                ),
              ),
            if (snap != null && snap.peers.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final peer in snap.peers) _PeerRow(peer: peer, color: foreground),
            ],
            if (snap != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'This phone: ${formatDeviceId(snap.localDeviceId)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeerRow extends StatelessWidget {
  const _PeerRow({required this.peer, required this.color});
  final PeerStatus peer;
  final Color color;

  String _ago(DateTime? t) {
    if (t == null) return 'never';
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 60) return '${s}s ago';
    return '${s ~/ 60} min ago';
  }

  @override
  Widget build(BuildContext context) {
    final name = peer.deviceId == null ? 'Identifying…' : 'Phone ${formatDeviceId(peer.deviceId!)}';
    final traffic = 'sent ${peer.sent} · received ${peer.received} · seen ${_ago(peer.lastSeen)}';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(peer.connected ? Icons.link : Icons.phone_android, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                Text(traffic, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
                if (peer.lastError != null)
                  Text(
                    'Last exchange failed — retrying automatically',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyCropsCard extends ConsumerWidget {
  const _MyCropsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(farmerProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();
    final mine = profile.myCropIds.toSet();
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        title: const Text('Crops I grow'),
        subtitle: Text(
          mine.isEmpty
              ? 'Not set — alerts for every crop are treated alike'
              : cropCatalog.where((c) => mine.contains(c.id)).map((c) => c.id.replaceAll('_', ' ')).join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text(
            'Alerts about your crops are passed on to nearby phones first.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final crop in cropCatalog)
                FilterChip(
                  label: Text(crop.id == 'staple_crops' ? 'Staple crops' : crop.displayName),
                  selected: mine.contains(crop.id),
                  onSelected: (selected) async {
                    final next = {...mine};
                    selected ? next.add(crop.id) : next.remove(crop.id);
                    await profile.setMyCropIds(next.toList());
                    ref.invalidate(farmerProfileProvider);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          ?action,
        ],
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
        title: Text(prettyDiseaseLabel(alert.label)),
        subtitle: Text(
          '${alert.detectionCount} reports within ${alert.radiusKm.toStringAsFixed(0)} km · '
          'since ${DateFormat.yMMMd().format(alert.windowStart)}'
          '${viaP2p ? ' · via nearby phones' : ''}',
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.row, required this.localDeviceId});
  final P2pPacket row;
  final String? localDeviceId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = DeviceIdentity.shortIdOfPublicKeyHex(row.sourceDeviceId);
    final mine = source == localDeviceId;
    final from = row.receivedFromPeerId?.replaceFirst('dev:', '');
    final origin = mine
        ? 'Your report'
        : 'Reported by phone ${formatDeviceId(source)}'
            '${from != null && from != source ? ', relayed by ${formatDeviceId(from)}' : ''}';
    return Card(
      child: ListTile(
        leading: Icon(mine ? Icons.campaign_outlined : Icons.bluetooth, color: theme.colorScheme.primary),
        title: Text(prettyDiseaseLabel(row.label)),
        subtitle: Text(
          '$origin\n'
          '${row.cropId.replaceAll('_', ' ')} · ${row.severity} severity · '
          '${(row.confidence * 100).toStringAsFixed(0)}% · ${DateFormat.MMMd().add_jm().format(row.observedAt.toLocal())}',
        ),
        isThreeLine: true,
        trailing: row.verified
            ? Tooltip(message: 'Signature verified', child: Icon(Icons.verified, color: theme.colorScheme.primary))
            : Tooltip(message: 'Unverified — signature missing or invalid', child: Icon(Icons.gpp_maybe, color: theme.colorScheme.error)),
      ),
    );
  }
}

/// "a1b2c3d4e5f60708" → "a1b2-c3d4", short enough to read aloud between
/// two farmers comparing phones.
String formatDeviceId(String id) =>
    id.length >= 8 ? '${id.substring(0, 4)}-${id.substring(4, 8)}' : id;
