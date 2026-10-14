import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/sync/sync_manager.dart';
import '../data/cart_controller.dart';
import '../data/orders_repository.dart';
import '../domain/order_models.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farm supplies'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Catalog'),
            Tab(text: 'Cart'),
            Tab(text: 'History'),
          ]),
        ),
        body: const TabBarView(
          children: [_CatalogTab(), _CartTab(), _HistoryTab()],
        ),
      ),
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersRepositoryProvider).refreshCatalog(),
      child: catalog.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No products yet. Pull to refresh.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final qty = ref.watch(cartControllerProvider)[item.id] ?? 0;
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.category} · ${currency.format(item.pricePerUnit)}/${item.unit}'),
                  trailing: qty == 0
                      ? OutlinedButton(
                          onPressed: () => ref.read(cartControllerProvider.notifier).increment(item.id),
                          child: const Text('Add'),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref.read(cartControllerProvider.notifier).decrement(item.id),
                            ),
                            Text('$qty'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => ref.read(cartControllerProvider.notifier).increment(item.id),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load catalog: $e')),
      ),
    );
  }
}

class _CartTab extends ConsumerWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final catalog = ref.watch(catalogProvider).value ?? [];
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (cart.isEmpty) {
      return const Center(child: Text('Cart is empty — add items from Catalog.'));
    }

    final lines = cart.entries.map((entry) {
      final product = catalog.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => CatalogItem(id: entry.key, name: entry.key, category: '', pricePerUnit: 0, unit: ''),
      );
      return OrderLineItem(
        productId: product.id,
        productName: product.name,
        quantity: entry.value,
        unitPrice: product.pricePerUnit,
      );
    }).toList();
    final total = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: lines
                .map((l) => ListTile(
                      title: Text(l.productName),
                      subtitle: Text('${l.quantity} × ${currency.format(l.unitPrice)}'),
                      trailing: Text(currency.format(l.lineTotal)),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(currency.format(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(ordersRepositoryProvider).placeOrder(lines);
                    ref.read(cartControllerProvider.notifier).clear();
                    // Upload right away when online; otherwise it stays queued.
                    ref.read(syncManagerProvider).syncDomain('orders');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order placed. It is sent to the supplier as soon as you are online.')),
                      );
                      DefaultTabController.of(context).animateTo(2);
                    }
                  },
                  child: const Text('Place order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return orders.when(
      data: (list) {
        if (list.isEmpty) return const Center(child: Text('No orders yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final order = list[index];
            return Card(
              child: ExpansionTile(
                leading: Icon(
                  order.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload_outlined,
                  color: order.syncStatus == 'synced' ? Colors.green : Colors.grey,
                ),
                title: Text('${DateFormat.yMMMd().add_jm().format(order.createdAt)} · ${currency.format(order.totalAmount)}'),
                subtitle: Text('${order.items.length} item${order.items.length == 1 ? '' : 's'} · '
                    '${order.syncStatus == 'synced' ? 'Received by supplier (demo)' : 'Waiting to send'}'),
                children: order.items
                    .map((i) => ListTile(
                          title: Text(i.productName),
                          trailing: Text('${i.quantity} × ${currency.format(i.unitPrice)}'),
                        ))
                    .toList(),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load orders: $e')),
    );
  }
}
