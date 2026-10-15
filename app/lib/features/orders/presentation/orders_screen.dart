import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/server_status.dart';
import '../../../core/settings/farm_setup.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../shared/widgets/ui.dart';
import '../data/marketplace_repository.dart';
import '../data/orders_repository.dart';
import '../domain/listing.dart';
import '../domain/order_models.dart';

final _rupees0 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _rupees2 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// ₹1,350 — or ₹266.50 when there are paise (urea's fixed MRP).
String _money(num v) => v == v.roundToDouble() ? _rupees0.format(v) : _rupees2.format(v);
String _qty(double q) => q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toString();

IconData _categoryIcon(String c) => switch (c) {
      'Produce' => Icons.grass,
      'Seed' => Icons.spa_outlined,
      'Fertilizer' => Icons.science_outlined,
      'Pesticide' => Icons.pest_control_outlined,
      'Equipment' => Icons.agriculture_outlined,
      'Livestock' => Icons.pets_outlined,
      _ => Icons.inventory_2_outlined,
    };

/// Farm supplies: Buy (needs the AgriEdge server) and Sell (works offline,
/// uploads when connected).
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_sync);
  }

  Future<void> _sync() async {
    final sync = ref.read(syncManagerProvider);
    await sync.syncDomain('listings');
    await sync.syncDomain('orders');
    if (mounted) ref.invalidate(listingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farm supplies'),
          actions: [
            IconButton(
              tooltip: 'My orders',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _MyOrdersPage())),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Buy'),
            Tab(icon: Icon(Icons.sell_outlined), text: 'Sell'),
          ]),
        ),
        body: TabBarView(children: [_BuyTab(onRefresh: _sync), _SellTab(onRefresh: _sync)]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Buy

class _ConnectionBanner extends ConsumerWidget {
  const _ConnectionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final reachable = ref.watch(serverReachableProvider);
    final (IconData icon, String text, Color bg, Color fg, bool retry) = switch (reachable) {
      AsyncData(value: true) => (
          Icons.cloud_done_outlined,
          'Connected to the AgriEdge server. You can buy.',
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          false
        ),
      AsyncData(value: false) || AsyncError() => (
          Icons.cloud_off_outlined,
          'Not connected to the AgriEdge server. You can browse, but buying needs a connection.',
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          true
        ),
      _ => (Icons.sync, 'Checking connection…', scheme.surfaceContainerHighest, scheme.onSurfaceVariant, false),
    };
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg))),
          if (retry)
            TextButton(onPressed: () => ref.invalidate(serverReachableProvider), child: const Text('Check')),
        ]),
      ),
    );
  }
}

class _BuyTab extends ConsumerWidget {
  const _BuyTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(listingsProvider).value;
    final catalog = ref.watch(catalogProvider).value ?? const <CatalogItem>[];
    final canBuy = ref.watch(serverReachableProvider).value ?? false;
    final forSale = listings?.forSale ?? const <Listing>[];
    final at = listings?.fetchedAt;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(serverReachableProvider);
        await onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _ConnectionBanner(),
          SectionHeader('From farmers',
              action: at == null
                  ? null
                  : SourceTag(
                      text: listings?.via != null ? 'via nearby phone · ${timeAgo(at.toLocal())}' : 'updated ${timeAgo(at.toLocal())}',
                      warning: listings?.via != null)),
          if (forSale.isEmpty)
            const Card(
                child: StateMessage(
                    compact: true, icon: Icons.storefront_outlined, text: 'No farmer listings yet. Pull down to refresh.'))
          else
            for (final l in forSale) _ListingCard(listing: l, canBuy: canBuy),
          const SectionHeader('AgriEdge store'),
          if (catalog.isEmpty)
            const Card(child: StateMessage(compact: true, icon: Icons.inventory_2_outlined, text: 'Store items appear after the first sync.'))
          else
            for (final p in catalog) _ProductCard(product: p, canBuy: canBuy),
        ],
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing, required this.canBuy});
  final Listing listing;
  final bool canBuy;

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final l = listing;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Buy ${l.title}?'),
        content: Text('${_qty(l.quantity)} ${l.unit} from ${l.sellerName} for ${_money(l.total)}.\n\n'
            'Payment and pickup are arranged with the seller.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Buy')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final r = await ref.read(marketplaceRepositoryProvider).buyListing(l);
      ref.invalidate(listingsProvider);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline),
          title: const Text('Bought'),
          content: Text('It is now marked sold, and ${r.seller} sees that in their listings. '
              '${r.phone == null || r.phone!.isEmpty ? '' : 'Call ${r.seller} on ${r.phone} to arrange pickup. '}'
              'You can follow it in My orders.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );
    } on PurchaseException catch (e) {
      ref.invalidate(listingsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(_categoryIcon(l.category), color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.title, style: theme.textTheme.titleMedium),
                Text('${_qty(l.quantity)} ${l.unit} · ${_money(l.price)}/${l.unit}'),
                Text([l.sellerName, if (l.place != null && l.place!.isNotEmpty) l.place, timeAgo(l.createdAt.toLocal())].join(' · '),
                    style: theme.textTheme.bodySmall),
                if (l.note != null && l.note!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.note!, style: theme.textTheme.bodySmall)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(_money(l.total), style: theme.textTheme.titleMedium)),
            FilledButton.tonal(onPressed: canBuy ? () => _buy(context, ref) : null, child: const Text('Buy')),
          ]),
        ]),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.canBuy});
  final CatalogItem product;
  final bool canBuy;

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    var qty = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text(product.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: qty > 1 ? () => setState(() => qty--) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text('$qty ${product.unit}${qty == 1 ? '' : 's'}', style: Theme.of(c).textTheme.titleMedium),
              IconButton(onPressed: qty < 50 ? () => setState(() => qty++) : null, icon: const Icon(Icons.add_circle_outline)),
            ]),
            Text('Total ${_money(product.pricePerUnit * qty)}'),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Buy')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(marketplaceRepositoryProvider).buyProduct(product, qty);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Order placed. Follow it in My orders.')));
      }
    } on PurchaseException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(_categoryIcon(p.category), color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: theme.textTheme.titleMedium),
                if (p.description != null) Text(p.description!, style: theme.textTheme.bodySmall),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('${_money(p.pricePerUnit)} / ${p.unit}', style: theme.textTheme.titleMedium)),
            FilledButton.tonal(onPressed: canBuy ? () => _buy(context, ref) : null, child: const Text('Buy')),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Sell

class _SellTab extends ConsumerWidget {
  const _SellTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(listingsProvider).value?.mine ?? const <Listing>[];
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Sell to farmers nearby', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text('List produce, seed, fertiliser or tools. Your listing goes to the AgriEdge server as soon as '
                    'you are connected, and nearby phones see it over Bluetooth.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (_) => const _SellSheet(),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('List something for sale'),
                ),
              ]),
            ),
          ),
          const SectionHeader('My listings'),
          if (mine.isEmpty)
            const Card(child: StateMessage(compact: true, icon: Icons.sell_outlined, text: 'Nothing listed yet.'))
          else
            for (final l in mine) _MyListingCard(listing: l),
        ],
      ),
    );
  }
}

class _MyListingCard extends ConsumerWidget {
  const _MyListingCard({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing;
    final theme = Theme.of(context);
    final (String status, bool warn) = l.pending
        ? ('Waiting for connection', true)
        : switch (l.status) {
            'sold' => ('Sold', false),
            'withdrawn' => ('Taken down', false),
            _ => ('For sale', false),
          };
    final canWithdraw = l.pending || l.status == 'available';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(_categoryIcon(l.category), color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.title, style: theme.textTheme.titleMedium),
              Text('${_qty(l.quantity)} ${l.unit} · ${_money(l.price)}/${l.unit}'),
              const SizedBox(height: 4),
              SourceTag(text: status, warning: warn),
            ]),
          ),
          if (canWithdraw)
            IconButton(
              tooltip: 'Take down',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                try {
                  await ref.read(marketplaceRepositoryProvider).withdraw(l);
                } on PurchaseException catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {}
                ref.invalidate(listingsProvider);
              },
            ),
        ]),
      ),
    );
  }
}

class _SellSheet extends ConsumerStatefulWidget {
  const _SellSheet();
  @override
  ConsumerState<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends ConsumerState<_SellSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _place = TextEditingController();
  final _note = TextEditingController();
  String _category = 'Produce';
  String _unit = 'quintal';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _place.text = ref.read(farmSetupProvider).location?.label ?? '';
    ref.read(marketplaceRepositoryProvider).lastSeller().then((s) {
      if (!mounted) return;
      if (_name.text.isEmpty) _name.text = s.name;
      if (_phone.text.isEmpty) _phone.text = s.phone;
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _qty, _price, _name, _phone, _place, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _example() => setState(() {
        _title.text = 'Onion (fresh harvest)';
        _category = 'Produce';
        _qty.text = '5';
        _unit = 'quintal';
        _price.text = '1800';
        if (_name.text.isEmpty) _name.text = 'Ravi Kumar';
        _note.text = 'Medium size, dried 3 days. Pickup from farm.';
      });

  String? _positive(String? v) {
    final n = double.tryParse((v ?? '').trim());
    return n == null || n <= 0 ? 'Enter a number' : null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(marketplaceRepositoryProvider);
    await repo.post(
      sellerName: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      title: _title.text.trim(),
      category: _category,
      quantity: double.parse(_qty.text.trim()),
      unit: _unit,
      price: double.parse(_price.text.trim()),
      place: _place.text.trim().isEmpty ? null : _place.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    final uploaded = await ref.read(syncManagerProvider).syncDomain('listings');
    ref.invalidate(listingsProvider);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(uploaded
          ? 'Listed for sale. Farmers can buy it now.'
          : 'Saved on this phone. It goes live as soon as you are connected to the AgriEdge server.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text('List for sale', style: theme.textTheme.titleLarge)),
              TextButton.icon(onPressed: _example, icon: const Icon(Icons.auto_fix_high), label: const Text('Fill example')),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What are you selling?'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [for (final c in Listing.categories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  validator: _positive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_unit),
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [for (final u in Listing.units) DropdownMenuItem(value: u, child: Text(u))],
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Price per $_unit (₹)'),
              validator: _positive,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional, shown to the buyer)'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _place, decoration: const InputDecoration(labelText: 'Village / town')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLength: 280,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sell_outlined),
              label: const Text('List for sale'),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- My orders

class _MyOrdersPage extends ConsumerWidget {
  const _MyOrdersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncManagerProvider).syncDomain('orders'),
        child: orders.when(
          data: (list) => list.isEmpty
              ? ListView(children: const [StateMessage(icon: Icons.receipt_long_outlined, text: 'No orders yet.')])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final order = list[index];
                    return Card(
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: Icon(
                          order.syncStatus == 'synced' ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                          color: order.syncStatus == 'synced' ? Colors.green : Colors.grey,
                        ),
                        title: Text('${DateFormat.yMMMd().add_jm().format(order.createdAt)} · ${_money(order.totalAmount)}'),
                        subtitle: Text('${order.items.length} item${order.items.length == 1 ? '' : 's'} · '
                            '${order.syncStatus == 'synced' ? _statusText(order.status) : 'Waiting to send'}'),
                        children: [
                          for (final i in order.items)
                            ListTile(
                              title: Text(i.productName),
                              trailing: Text('${i.quantity} × ${_money(i.unitPrice)}'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [StateMessage(icon: Icons.error_outline, text: 'Could not load orders: $e')]),
        ),
      ),
    );
  }
}

String _statusText(String status) => switch (status) {
      'received' => 'Received',
      'packed' => 'Packed',
      'shipped' => 'On the way',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => status,
    };
