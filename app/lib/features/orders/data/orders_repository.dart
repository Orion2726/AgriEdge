import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../domain/order_models.dart';

class OrdersRepository implements OfflineRepository<FarmOrder> {
  OrdersRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;
  final _uuid = const Uuid();

  Stream<List<CatalogItem>> watchCatalog() {
    return _db.select(_db.products).watch().map(
          (rows) => rows
              .map((r) => CatalogItem(
                    id: r.id,
                    name: r.name,
                    category: r.category,
                    pricePerUnit: r.pricePerUnit,
                    unit: r.unit,
                    imageUrl: r.imageUrl,
                    description: r.description,
                  ))
              .toList(),
        );
  }

  Future<void> refreshCatalog() async {
    final res = await _dio.get('/api/products');
    final rows = (res.data as List).cast<Map<String, dynamic>>();
    await _db.batch((b) {
      b.deleteAll(_db.products);
      b.insertAll(
        _db.products,
        rows.map(
          (r) => ProductsCompanion.insert(
            id: r['id'] as String,
            name: r['name'] as String,
            category: r['category'] as String,
            pricePerUnit: (r['pricePerUnit'] as num).toDouble(),
            unit: r['unit'] as String,
            imageUrl: Value(r['imageUrl'] as String?),
            description: Value(r['description'] as String?),
          ),
        ),
      );
    });
  }

  @override
  Stream<List<FarmOrder>> watchAll() {
    final ordersStream = (_db.select(_db.orders)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
    return ordersStream.asyncMap((orderRows) async {
      final result = <FarmOrder>[];
      for (final order in orderRows) {
        final items = await (_db.select(_db.orderItems)..where((t) => t.orderId.equals(order.id))).get();
        result.add(FarmOrder(
          id: order.id,
          createdAt: order.createdAt,
          status: order.status,
          totalAmount: order.totalAmount,
          syncStatus: order.syncStatus,
          items: items
              .map((i) => OrderLineItem(
                    productId: i.productId,
                    productName: i.productName,
                    quantity: i.quantity,
                    unitPrice: i.unitPrice,
                  ))
              .toList(),
        ));
      }
      return result;
    });
  }

  Future<String> placeOrder(List<OrderLineItem> items) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now();
    final total = items.fold<double>(0, (sum, i) => sum + i.lineTotal);

    await _db.transaction(() async {
      await _db.into(_db.orders).insert(
            OrdersCompanion.insert(id: id, createdAt: createdAt, totalAmount: total),
          );
      await _db.batch((b) {
        b.insertAll(
          _db.orderItems,
          items.map(
            (i) => OrderItemsCompanion.insert(
              orderId: id,
              productId: i.productId,
              productName: i.productName,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            ),
          ),
        );
      });
      await _db.into(_db.syncQueueItems).insert(
            SyncQueueItemsCompanion.insert(type: 'order', refId: id, createdAt: createdAt),
          );
    });
    return id;
  }

  @override
  Future<void> refresh() async {
    await refreshCatalog();
    await _drainOrderQueue();
  }

  Future<void> _drainOrderQueue() async {
    final pending = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.type.equals('order') & t.status.equals('pending')))
        .get();

    for (final queueItem in pending) {
      final order = await (_db.select(_db.orders)..where((t) => t.id.equals(queueItem.refId))).getSingleOrNull();
      if (order == null) continue;
      final items = await (_db.select(_db.orderItems)..where((t) => t.orderId.equals(order.id))).get();
      try {
        await _dio.post('/api/orders', data: {
          'id': order.id,
          'createdAt': order.createdAt.toIso8601String(),
          'totalAmount': order.totalAmount,
          'items': items
              .map((i) => {
                    'productId': i.productId,
                    'productName': i.productName,
                    'quantity': i.quantity,
                    'unitPrice': i.unitPrice,
                  })
              .toList(),
        });
        await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(queueItem.id)))
            .write(const SyncQueueItemsCompanion(status: Value('synced')));
        await (_db.update(_db.orders)..where((t) => t.id.equals(order.id)))
            .write(const OrdersCompanion(syncStatus: Value('synced')));
      } catch (_) {
        await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(queueItem.id))).write(
          SyncQueueItemsCompanion(attempts: Value(queueItem.attempts + 1)),
        );
      }
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final catalogProvider = StreamProvider<List<CatalogItem>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchCatalog();
});

final ordersProvider = StreamProvider<List<FarmOrder>>((ref) {
  return ref.watch(ordersRepositoryProvider).watchAll();
});
