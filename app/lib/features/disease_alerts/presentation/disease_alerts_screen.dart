import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ml/crop_catalog.dart';
import '../../../core/p2p/p2p_alert_service.dart';
import '../../../core/p2p/packet/p2p_packet.dart';
import '../../../core/p2p/relevance/farmer_profile.dart';
import '../../../core/p2p/security/device_identity.dart';
import '../../../core/p2p/snapshot_sync.dart';
import '../../../core/p2p/store/p2p_packet_store.dart';
import '../../../core/p2p/transport/p2p_transport.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/disease_label.dart';
import '../data/disease_alerts_repository.dart';
import '../domain/nearby_alert.dart';
import 'share_report_sheet.dart';

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
/// session for as long as the app is open (started by the tab shell), so
/// reports and shared data move between phones whichever tab is showing.
/// It is not an always-on background service.
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
      // The session normally runs app-wide (see _TabShell); this is the
      // "Try again" path after a failed start, or the first start.
      if (service.transportManager.state == P2pTransportState.running) {
        // Limited (scan-only) mode: ask Bluetooth to advertise again.
        await service.transportManager.retryAdvertising();
        return;
      }
      await service.stop();
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
        title: const Text('Nearby'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Send test alert (debug)',
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: _sendDebugTestAlert,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showShareReportSheet(context, ref),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Share a report'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshNetworkAlerts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _P2pStatusCard(session: session, onRetry: _startP2p),
              const SizedBox(height: 8),
              const _MyCropsCard(),
              const _SharedDataCard(),
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
              const _OtherRegionsSection(),
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
              ? 'Waiting for a nearby phone…'
              : 'Sharing with ${snap.peers.length} nearby phone${snap.peers.length == 1 ? '' : 's'}',
          false
        ),
      P2pTransportState.starting || P2pTransportState.stopped => (
          Icons.bluetooth,
          'Starting nearby sharing…',
          false
        ),
      P2pTransportState.bluetoothOff => (Icons.bluetooth_disabled, 'Turn on Bluetooth to share with nearby phones', true),
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
                if ((problem && state != P2pTransportState.unsupported && state != P2pTransportState.bluetoothOff) ||
                    (state == P2pTransportState.running && snap?.detail != null))
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(foregroundColor: foreground),
                    child: const Text('Try again'),
                  ),
              ],
            ),
            if (state == P2pTransportState.bluetoothOff)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Sharing starts again by itself once Bluetooth is on. Reports stay saved on this phone.',
                    style: TextStyle(color: foreground)),
              )
            else if ((problem || state == P2pTransportState.running) && snap?.detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(snap!.detail!, style: TextStyle(color: foreground)),
              ),
            if (state == P2pTransportState.running && snap!.peers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Reports and data are swapped automatically with any phone that has '
                  'AgriEdge open within Bluetooth range — no internet needed.',
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
    final traffic = 'in range ${_ago(peer.lastSeen)} · shared ${peer.sent} · got ${peer.received}';
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
                    'Connection dropped — trying again automatically',
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
    final payload = P2pPacketStore.payloadOf(row);
    final source = DeviceIdentity.shortIdOfPublicKeyHex(row.sourceDeviceId);
    final mine = source == localDeviceId;
    final from = row.receivedFromPeerId?.replaceFirst('dev:', '');
    final reachedPhones = (jsonDecode(row.forwardedToPeerIdsJson) as List).where((k) => k != row.receivedFromPeerId).length;
    final official = row.sourceDeviceId == serverSourceId;
    final origin = official
        ? 'Official report from AgriEdge server'
            '${from != null && from != serverSourceId ? ', relayed by phone ${formatDeviceId(from)}' : ''}'
        : mine
            ? 'Your report'
            : 'Farmer report from phone ${formatDeviceId(source)}'
                '${from != null && from != source ? ', passed on by ${formatDeviceId(from)}' : ''}';
    final details = [
      row.cropId.replaceAll('_', ' '),
      '${row.severity} severity',
      if (row.confidence > 0) '${(row.confidence * 100).toStringAsFixed(0)}% model confidence',
      DateFormat.MMMd().add_jm().format(row.observedAt.toLocal()),
    ].join(' · ');
    final states = <(IconData, String)>[
      if (official && from == serverSourceId) (Icons.cloud_download_outlined, 'Fetched from server')
      else if (mine) (Icons.save_outlined, 'Saved on this phone')
      else (Icons.move_to_inbox_outlined, 'Carried — passed on to phones you meet'),
      if (reachedPhones > 0) (Icons.check_circle_outline, 'Received by $reachedPhones nearby phone${reachedPhones == 1 ? '' : 's'}')
      else (Icons.schedule, 'Waiting for a nearby phone'),
      if (!official)
        if (row.syncedToBackend) (Icons.cloud_done_outlined, 'Uploaded to server') else (Icons.cloud_upload_outlined, 'Uploads when online'),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showReportDetails(context, row: row, payload: payload, origin: origin, official: official),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (payload.photoJpeg != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(payload.photoJpeg!, width: 72, height: 72, fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(prettyDiseaseLabel(row.label), style: theme.textTheme.titleMedium)),
                  if (official)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Official',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
                    ),
                  Tooltip(
                    message: row.verified ? 'Signed by the reporting phone' : 'Signature not checked yet or invalid',
                    child: Icon(row.verified ? Icons.verified : Icons.gpp_maybe,
                        size: 20, color: row.verified ? theme.colorScheme.primary : theme.colorScheme.error),
                  ),
                ]),
                Text(origin, style: theme.textTheme.bodySmall),
                Text(details, style: theme.textTheme.bodySmall),
                if (payload.note != null) ...[
                  const SizedBox(height: 6),
                  Text('“${payload.note}”', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 6),
                Wrap(spacing: 10, runSpacing: 2, children: [
                  for (final (icon, text) in states)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(text, style: theme.textTheme.labelSmall),
                    ]),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Tap on a report: the photo, what was predicted, exactly where, and when.
void _showReportDetails(
  BuildContext context, {
  required P2pPacket row,
  required DiseaseAlertPayload payload,
  required String origin,
  required bool official,
}) {
  final theme = Theme.of(context);
  final lat = row.lat.toStringAsFixed(5), lng = row.lng.toStringAsFixed(5);
  final disease = prettyDiseaseLabel(row.label);
  final crop = row.cropId.replaceAll('_', ' ');
  final prediction = official
      ? 'Official advisory: $disease on $crop'
      : row.confidence > 0
          ? 'The model thinks this is $disease on $crop (${(row.confidence * 100).toStringAsFixed(0)}% sure)'
          : 'The farmer reported $disease on $crop (seen by eye, no model check)';
  Widget line(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: theme.textTheme.labelLarge)),
          Expanded(child: Text(value)),
        ]),
      );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (payload.photoJpeg != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(payload.photoJpeg!, fit: BoxFit.cover, gaplessPlayback: true),
          ),
          const SizedBox(height: 14),
        ],
        Text(disease, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(prediction, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 10),
        line(Icons.warning_amber_rounded, 'Severity', row.severity[0].toUpperCase() + row.severity.substring(1)),
        line(Icons.place_outlined, 'Location', '$lat, $lng'),
        line(Icons.schedule, 'Seen', DateFormat.yMMMd().add_jm().format(row.observedAt.toLocal())),
        line(Icons.timer_off_outlined, 'Expires', DateFormat.yMMMd().add_jm().format(row.expiresAt.toLocal())),
        line(Icons.person_pin_circle_outlined, 'From', origin),
        line(row.verified ? Icons.verified : Icons.gpp_maybe, 'Signature',
            row.verified ? 'Signed by the reporting phone' : 'Not checked yet'),
        if (payload.note != null) line(Icons.notes, 'Note', '“${payload.note}”'),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=15/$lat/$lng'),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Open in Maps'),
        ),
      ]),
    ),
  );
}

/// Tap on an "Other regions" outbreak: what, where (centre of the reports),
/// how many, how sure, and where this phone got the information.
void _showRegionDetails(BuildContext context, RegionalOutbreak r, {String? via}) {
  final theme = Theme.of(context);
  final disease = prettyDiseaseLabel(r.label);
  final crop = r.cropId?.replaceAll('_', ' ');
  final hasPoint = r.lat != null && r.lng != null;
  final lat = r.lat?.toStringAsFixed(5), lng = r.lng?.toStringAsFixed(5);
  final reports = '${r.reportCount} report${r.reportCount == 1 ? '' : 's'}';
  final overview = [
    '$reports of $disease${crop == null ? '' : ' on $crop'} around ${r.region}',
    if (r.officialCount > 0) '${r.officialCount} of them official',
    if (r.avgConfidence != null) 'disease checks were ${(r.avgConfidence! * 100).round()}% sure on average',
  ].join(', ');
  Widget line(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(label, style: theme.textTheme.labelLarge)),
          Expanded(child: Text(value)),
        ]),
      );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(disease, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('$overview.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 10),
        line(Icons.public, 'Region', r.region),
        if (hasPoint) line(Icons.place_outlined, 'Centre', '$lat, $lng'),
        if (r.distanceKm != null) line(Icons.straighten, 'Distance', '${r.distanceKm} km from your farm'),
        line(Icons.summarize_outlined, 'Reports', reports),
        line(Icons.schedule, 'Latest', DateFormat.yMMMd().add_jm().format(r.latestAt.toLocal())),
        line(Icons.cloud_outlined, 'Source', via == null ? 'AgriEdge server' : 'AgriEdge server, passed on by $via'),
        if (hasPoint) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => launchUrl(
              Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=10/$lat/$lng'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open in Maps'),
          ),
        ],
      ]),
    ),
  );
}

/// "a1b2c3d4e5f60708" → "a1b2-c3d4", short enough to read aloud between
/// two farmers comparing phones.
String formatDeviceId(String id) =>
    id.length >= 8 ? '${id.substring(0, 4)}\u2011${id.substring(4, 8)}' : id; // non-breaking hyphen

final _receivedSnapshotsProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(p2pSessionSnapshotProvider); // refresh as the session changes
  return SnapshotSync.received();
});

/// What everyday data reached this phone from a neighbour.
class _SharedDataCard extends ConsumerWidget {
  const _SharedDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final got = ref.watch(_receivedSnapshotsProvider).value ?? const {};
    const names = {
      SnapshotKind.prices: 'Mandi prices',
      SnapshotKind.msp: 'MSP',
      SnapshotKind.weather: 'Weather forecast',
      SnapshotKind.news: 'Farm news',
      SnapshotKind.regions: 'Outbreaks in other regions',
      SnapshotKind.uploaded: 'Upload confirmations',
      SnapshotKind.listings: 'Farm supplies for sale',
    };
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        leading: const Icon(Icons.swap_horiz),
        title: const Text('Shared data'),
        subtitle: Text(got.isEmpty
            ? 'Prices, MSP, weather, news and listings are swapped with nearby phones'
            : 'Got ${got.length} update${got.length == 1 ? '' : 's'} from nearby phones'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final k in SnapshotKind.values)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(names[k]!),
              subtitle: Text(got[k] == null
                  ? 'Your own copy is used (or none yet)'
                  : 'From ${got[k]!.from} · data from ${DateFormat.MMMd().add_jm().format(got[k]!.dataAt.toLocal())}'),
            ),
          Text(
            'A phone only takes data that is newer than its own copy. The treatment guide, crop calendar '
            'and FAQ are built into the app, so every phone already has them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Outbreaks far away, from the central server (beyond Bluetooth range).
class _OtherRegionsSection extends ConsumerWidget {
  const _OtherRegionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regions = ref.watch(regionalOutbreaksProvider);
    final theme = Theme.of(context);
    final data = regions.value;
    final far = data?.items.where((r) => (r.distanceKm ?? 999) > 25).toList() ?? const <RegionalOutbreak>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
        child: Row(children: [
          Expanded(child: Text('Other regions', style: theme.textTheme.titleSmall)),
          if (data != null)
            Text(
              data.via != null
                  ? 'via ${data.via}'
                  : data.fromCache
                      ? 'saved ${DateFormat.MMMd().add_jm().format(data.fetchedAt)}'
                      : 'from AgriEdge server',
              style: theme.textTheme.labelSmall,
            ),
          IconButton(
            tooltip: 'Refresh',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.invalidate(regionalOutbreaksProvider),
          ),
        ]),
      ),
      if (regions.isLoading && data == null)
        const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
      else if (data == null)
        Card(
          child: ListTile(
            leading: const Icon(Icons.public_off),
            title: const Text('Connect to the AgriEdge server'),
            subtitle: const Text('See outbreaks in other districts and states, beyond Bluetooth range.'),
          ),
        )
      else if (far.isEmpty)
        const Card(child: ListTile(leading: Icon(Icons.public), title: Text('No outbreaks reported in other regions')))
      else
        Card(
          child: Column(children: [
            for (final r in far.take(8))
              ListTile(
                leading: Icon(Icons.location_on_outlined, color: theme.colorScheme.tertiary),
                title: Text('${prettyDiseaseLabel(r.label)}${r.cropId == null ? '' : ' · ${r.cropId!.replaceAll('_', ' ')}'}'),
                subtitle: Text('${r.region}${r.distanceKm == null ? '' : ' · ${r.distanceKm} km away'}\n'
                    '${r.reportCount} report${r.reportCount == 1 ? '' : 's'} · latest ${DateFormat.MMMd().format(r.latestAt.toLocal())}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRegionDetails(context, r, via: data.via),
              ),
          ]),
        ),
    ]);
  }
}
