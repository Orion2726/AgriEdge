import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/live_feeds.dart';
import '../../../core/db/app_database.dart';
import '../../../core/ml/crop_catalog.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/p2p/relevance/farmer_profile.dart';
import '../../../core/p2p/store/p2p_packet_store.dart';
import '../../../core/settings/farm_setup.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/disease_label.dart';
import '../../../shared/widgets/ui.dart';
import '../../market_price/data/market_price_repository.dart';
import '../../msp/data/msp_repository.dart';

final _recentReportsProvider = StreamProvider.autoDispose<List<P2pPacket>>(
    (ref) => ref.watch(p2pPacketStoreProvider).watchRecent(limit: 20));

/// Dashboard: weather, nearby alerts, quick actions, prices and news —
/// each section loads independently and keeps a saved copy for offline.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(farmSetupProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriEdge'),
        actions: [
          IconButton(
            tooltip: 'My farm',
            icon: const Icon(Icons.agriculture_outlined),
            onPressed: () => showFarmSetupSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(newsProvider);
          await ref.read(syncManagerProvider).syncAll();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (setup.loaded && !setup.setupDone) const _SetupCard(),
            const _WeatherCard(),
            const _AlertsSummary(),
            const SectionHeader('Quick actions'),
            const _QuickActions(),
            const _MarketSnapshot(),
            const _NewsSection(),
            const SizedBox(height: 8),
            const _SyncLine(),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ setup

class _SetupCard extends ConsumerWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome! Set up your farm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
          const SizedBox(height: 4),
          Text('Add your area and crops to get local weather and the alerts that matter to you.',
              style: TextStyle(color: scheme.onPrimaryContainer)),
          const SizedBox(height: 12),
          Row(children: [
            FilledButton(onPressed: () => showFarmSetupSheet(context), child: const Text('Set up')),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref.read(farmSetupProvider.notifier).finish(),
              child: Text('Skip', style: TextStyle(color: scheme.onPrimaryContainer)),
            ),
          ]),
        ]),
      ),
    );
  }
}

Future<void> showFarmSetupSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _FarmSetupSheet(),
    );

class _FarmSetupSheet extends ConsumerStatefulWidget {
  const _FarmSetupSheet();
  @override
  ConsumerState<_FarmSetupSheet> createState() => _FarmSetupSheetState();
}

class _FarmSetupSheetState extends ConsumerState<_FarmSetupSheet> {
  String? _gpsMessage;
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(farmSetupProvider);
    final profile = ref.watch(farmerProfileProvider).value;
    final mine = profile?.myCropIds.toSet() ?? {};
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('My farm', style: Theme.of(context).textTheme.titleLarge),
          const SectionHeader('Where is your farm?'),
          if (setup.location != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.place_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(setup.location!.label)),
              ]),
            ),
          FilledButton.tonalIcon(
            onPressed: _locating
                ? null
                : () async {
                    setState(() => _locating = true);
                    final msg = await ref.read(farmSetupProvider.notifier).useGps();
                    if (mounted) {
                      setState(() {
                        _gpsMessage = msg;
                        _locating = false;
                      });
                    }
                  },
            icon: _locating
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Use my current location'),
          ),
          if (_gpsMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_gpsMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: presetLocations.any((p) => p.label == setup.location?.label) ? setup.location!.label : null,
            decoration: const InputDecoration(labelText: 'Or choose your area'),
            items: [for (final p in presetLocations) DropdownMenuItem(value: p.label, child: Text(p.label))],
            onChanged: (v) => ref
                .read(farmSetupProvider.notifier)
                .setLocation(presetLocations.firstWhere((p) => p.label == v)),
          ),
          const SectionHeader('Crops I grow'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final crop in cropCatalog)
              FilterChip(
                label: Text(crop.id == 'staple_crops' ? 'Corn / sugarcane' : crop.displayName),
                selected: mine.contains(crop.id),
                onSelected: profile == null
                    ? null
                    : (sel) async {
                        final next = {...mine};
                        sel ? next.add(crop.id) : next.remove(crop.id);
                        await profile.setMyCropIds(next.toList());
                        ref.invalidate(farmerProfileProvider);
                      },
              ),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(farmSetupProvider.notifier).finish();
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- weather

class _WeatherCard extends ConsumerWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider);
    final loc = ref.watch(farmSetupProvider).location;
    final scheme = Theme.of(context).colorScheme;
    if (loc == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_outlined),
          title: const Text('Local weather'),
          subtitle: const Text('Set your farm location to see rain and heat warnings.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showFarmSetupSheet(context),
        ),
      );
    }
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: weather.when(
          loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
          error: (_, _) => StateMessage(
            compact: true,
            icon: Icons.cloud_off,
            text: 'Weather unavailable — no internet and no saved forecast yet.',
            onRetry: () => ref.invalidate(weatherProvider),
          ),
          data: (feed) {
            final w = feed!.data;
            final on = scheme.onSecondaryContainer;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${w.tempC.round()}°', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: on)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(weatherLabel(w.code), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: on)),
                    Text(loc.label, style: TextStyle(color: on), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                for (final d in w.days.take(5))
                  Expanded(
                    child: Column(children: [
                      Text(DateFormat.E().format(d.date), style: TextStyle(color: on, fontWeight: FontWeight.w600)),
                      Text('${d.maxC.round()}°/${d.minC.round()}°', style: TextStyle(color: on)),
                      Text('💧${d.rainChance}%', style: TextStyle(color: on, fontSize: 12)),
                    ]),
                  ),
              ]),
              const SizedBox(height: 10),
              for (final tip in w.advice)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.lightbulb_outline, size: 18, color: on),
                    const SizedBox(width: 6),
                    Expanded(child: Text(tip, style: TextStyle(color: on))),
                  ]),
                ),
              const SizedBox(height: 8),
              SourceTag(
                text: 'Open-Meteo · ${feed.fromCache ? 'saved ' : 'updated '}${timeAgo(feed.fetchedAt)}',
                warning: feed.fromCache,
              ),
            ]);
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- alerts

class _AlertsSummary extends ConsumerWidget {
  const _AlertsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(_recentReportsProvider).value ?? const [];
    final mine = ref.watch(farmerProfileProvider).value?.myCropIds.toSet() ?? {};
    final relevant = reports.where((r) => mine.contains(r.cropId)).length;
    final scheme = Theme.of(context).colorScheme;
    final hasAlerts = reports.isNotEmpty;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasAlerts ? scheme.errorContainer : scheme.surfaceContainerHighest,
          child: Icon(Icons.warning_amber_rounded, color: hasAlerts ? scheme.onErrorContainer : scheme.outline),
        ),
        title: Text(hasAlerts
            ? '${reports.length} disease report${reports.length == 1 ? '' : 's'} nearby'
            : 'No disease reports nearby'),
        subtitle: Text(hasAlerts
            ? (mine.isEmpty
                ? 'Latest: ${prettyDiseaseLabel(reports.first.label)} on ${reports.first.cropId.replaceAll('_', ' ')}'
                : '$relevant about crops you grow · latest: ${prettyDiseaseLabel(reports.first.label)}')
            : 'Reports from farmers around you appear here, even without internet.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/nearby'),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String route) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => route.startsWith('/nearby') ? context.go(route) : context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
              ]),
            ),
          ),
        );
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      item(Icons.camera_alt_outlined, 'Check\ndisease', '/disease-detection'),
      item(Icons.science_outlined, 'Soil\ntest', '/soil-report'),
      item(Icons.eco_outlined, 'Crop\nadvice', '/crop-recommendation'),
      item(Icons.campaign_outlined, 'Nearby\nalerts', '/nearby'),
    ]);
  }
}

// ----------------------------------------------------------------- market

class _MarketSnapshot extends ConsumerWidget {
  const _MarketSnapshot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prices = ref.watch(marketPricesProvider).value ?? const [];
    final msp = {for (final m in ref.watch(mspRatesProvider).value ?? const []) m.crop: m};
    final mine = ref.watch(farmerProfileProvider).value?.myCropIds.toSet() ?? {};
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final sorted = [...prices]
      ..sort((a, b) => (mine.contains(b.commodity.toLowerCase()) ? 1 : 0) - (mine.contains(a.commodity.toLowerCase()) ? 1 : 0));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('Mandi prices', action: TextButton(onPressed: () => context.go('/market'), child: const Text('See all'))),
      if (sorted.isEmpty)
        const Card(child: StateMessage(compact: true, icon: Icons.storefront_outlined, text: 'No prices saved yet. They appear after the first sync with the AgriEdge server.'))
      else
        Card(
          child: Column(children: [
            for (final p in sorted.take(4))
              ListTile(
                dense: true,
                title: Text(p.commodity, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text('${p.mandi} · ${DateFormat.MMMd().format(p.priceDate)}'),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${currency.format(p.pricePerQuintal)}/qtl', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (msp[p.commodity] != null)
                    Text('MSP ${currency.format(msp[p.commodity]!.pricePerQuintal)}', style: Theme.of(context).textTheme.labelSmall),
                ]),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(alignment: Alignment.centerLeft, child: SourceTag(text: 'Sample prices from the AgriEdge demo server — not live mandi data', warning: true)),
            ),
          ]),
        ),
    ]);
  }
}

// ------------------------------------------------------------------- news

class _NewsSection extends ConsumerWidget {
  const _NewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Farm news'),
      news.when(
        loading: () => const Card(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))),
        error: (_, _) => Card(
          child: StateMessage(
            compact: true,
            icon: Icons.wifi_off,
            text: 'News needs internet. It will appear the next time you are online.',
            onRetry: () => ref.invalidate(newsProvider),
          ),
        ),
        data: (feed) => Column(children: [
          if (feed.fromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SourceTag(text: 'Offline — saved ${timeAgo(feed.fetchedAt)}', warning: true),
            ),
          for (final item in feed.data.take(6)) _NewsTile(item: item),
        ]),
      ),
    ]);
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => launchUrl(Uri.parse(item.link), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (item.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.summary, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Text(
              '${item.source}${item.published == null ? '' : ' · ${DateFormat.MMMd().add_jm().format(item.published!)}'} · Open ↗',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SyncLine extends ConsumerWidget {
  const _SyncLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    final last = ref.watch(domainSyncStatusProvider('market_price')).value;
    final text = !online
        ? 'Offline — showing saved information'
        : last?.lastError != null
            ? 'AgriEdge server not reachable — tap to check'
            : last?.lastSyncedAt != null
                ? 'Synced ${timeAgo(last!.lastSyncedAt!)}'
                : 'Not synced yet';
    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('/sync-settings'),
        icon: Icon(online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 18),
        label: Text(text),
      ),
    );
  }
}
