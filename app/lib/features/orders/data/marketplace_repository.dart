import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/p2p/p2p_alert_service.dart';
import '../../../core/p2p/snapshot_sync.dart' show listingsCacheKey;
import '../../../core/sync/sync_manager.dart';
import '../domain/listing.dart';
import '../domain/order_models.dart';
import 'orders_repository.dart';

/// What the Buy and Sell tabs show.
class ListingsView {
  const ListingsView({required this.forSale, required this.mine, this.fetchedAt, this.via});

  /// Other farmers' listings that are still available.
  final List<Listing> forSale;

  /// This phone's own listings (any status), newest first, incl. not yet uploaded.
  final List<Listing> mine;
  final DateTime? fetchedAt;

  /// Set when the copy came from a nearby phone over Bluetooth.
  final String? via;
}

/// A purchase the server turned down, e.g. "just sold to someone else".
class PurchaseException implements Exception {
  const PurchaseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Farm-supplies marketplace. Listings are cached as JSON (no database
/// migration needed) and passed to offline phones over Bluetooth; buying
/// always goes straight to the server so an item can only be sold once.
class MarketplaceRepository {
  MarketplaceRepository(this._ref);
  final Ref _ref;

  static const _pendingKey = 'market_listings_pending_v1';
  static const _mineKey = 'market_listings_mine_v1';
  static const _sellerKey = 'market_seller_v1';
  final _uuid = const Uuid();

  Dio get _dio => _ref.read(apiClientProvider);

  /// The server identifies phones by the P2P device id header, which is set
  /// once the P2P service has loaded.
  Future<void> _ensureDeviceId() async {
    try {
      await _ref.read(p2pAlertServiceFutureProvider.future);
    } catch (_) {}
  }

  Future<ListingsView> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mineIds = (prefs.getStringList(_mineKey) ?? const []).toSet();
    final pending = [
      for (final j in _decodeList(prefs.getString(_pendingKey))) Listing.fromJson(j, pending: true),
    ];
    final cache = prefs.getString(listingsCacheKey);
    var all = <Listing>[];
    DateTime? at;
    String? via;
    if (cache != null) {
      final m = jsonDecode(cache) as Map<String, dynamic>;
      at = DateTime.tryParse(m['at'] as String? ?? '');
      via = m['via'] as String?;
      all = [for (final j in (m['items'] as List? ?? const []).cast<Map>()) Listing.fromJson(j.cast<String, dynamic>())];
    }
    final pendingIds = {for (final p in pending) p.id};
    return ListingsView(
      forSale: [for (final l in all) if (!mineIds.contains(l.id) && l.status == 'available') l],
      mine: [...pending, for (final l in all) if (mineIds.contains(l.id) && !pendingIds.contains(l.id)) l],
      fetchedAt: at,
      via: via,
    );
  }

  /// Uploads listings posted offline, then fetches the current ones.
  Future<void> refresh() async {
    await _ensureDeviceId();
    final prefs = await SharedPreferences.getInstance();
    final pending = _decodeList(prefs.getString(_pendingKey));
    final left = <Map<String, dynamic>>[];
    Object? firstError;
    for (final j in pending) {
      try {
        await _dio.post('/api/listings', data: j);
      } catch (e) {
        firstError ??= e;
        left.add(j);
      }
    }
    await prefs.setString(_pendingKey, jsonEncode(left));
    final res = await _dio.get('/api/listings');
    final items = [
      for (final j in (res.data as List).cast<Map<String, dynamic>>()) Listing.fromJson(j).toJson(),
    ];
    await prefs.setString(listingsCacheKey, jsonEncode({'at': DateTime.now().toUtc().toIso8601String(), 'items': items}));
    if (firstError != null) throw SyncIncompleteException('${left.length} listings', firstError);
  }

  /// Saves a listing on this phone and uploads it now if the server answers.
  Future<void> post({
    required String sellerName,
    String? phone,
    required String title,
    required String category,
    required double quantity,
    required String unit,
    required double price,
    String? place,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final listing = Listing(
      id: 'lst-${_uuid.v4()}',
      sellerName: sellerName,
      phone: phone,
      title: title,
      category: category,
      quantity: quantity,
      unit: unit,
      price: price,
      place: place,
      note: note,
      createdAt: DateTime.now(),
    );
    await prefs.setString(_pendingKey, jsonEncode([..._decodeList(prefs.getString(_pendingKey)), listing.toJson()]));
    await prefs.setStringList(_mineKey, [...?prefs.getStringList(_mineKey), listing.id]);
    await prefs.setString(_sellerKey, jsonEncode({'name': sellerName, 'phone': phone}));
  }

  Future<({String name, String phone})> lastSeller() async {
    final prefs = await SharedPreferences.getInstance();
    final m = jsonDecode(prefs.getString(_sellerKey) ?? '{}') as Map<String, dynamic>;
    return (name: m['name'] as String? ?? '', phone: m['phone'] as String? ?? '');
  }

  /// Buys a farmer's listing. Needs the server; throws [PurchaseException]
  /// with a message to show when it can't go through.
  Future<({String seller, String? phone, double total})> buyListing(Listing l) async {
    await _ensureDeviceId();
    final orderId = _uuid.v4();
    try {
      final res = await _dio.post('/api/listings/${l.id}/buy', data: {'orderId': orderId});
      final body = res.data as Map<String, dynamic>;
      await _ref.read(ordersRepositoryProvider).recordPurchase(
            id: orderId,
            status: body['status'] as String? ?? 'received',
            items: [
              OrderLineItem(
                productId: 'listing:${l.id}',
                productName: '${l.title} (${_qty(l.quantity)} ${l.unit}) from ${l.sellerName}',
                quantity: 1,
                unitPrice: l.total,
              ),
            ],
          );
      return (seller: l.sellerName, phone: body['phone'] as String?, total: l.total);
    } on DioException catch (e) {
      throw PurchaseException(_message(e));
    } finally {
      refresh().ignore(); // drop the sold listing from the list
    }
  }

  /// Buys from the AgriEdge store catalogue. Needs the server.
  Future<void> buyProduct(CatalogItem p, int quantity) async {
    await _ensureDeviceId();
    final orderId = _uuid.v4();
    final items = [OrderLineItem(productId: p.id, productName: p.name, quantity: quantity, unitPrice: p.pricePerUnit)];
    try {
      final res = await _dio.post('/api/orders', data: {
        'id': orderId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'totalAmount': p.pricePerUnit * quantity,
        'items': [
          for (final i in items)
            {'productId': i.productId, 'productName': i.productName, 'quantity': i.quantity, 'unitPrice': i.unitPrice}
        ],
      });
      await _ref.read(ordersRepositoryProvider).recordPurchase(
          id: orderId, status: (res.data as Map)['status'] as String? ?? 'received', items: items);
    } on DioException catch (e) {
      throw PurchaseException(_message(e));
    }
  }

  /// Takes one of this phone's listings down (or drops it if not uploaded yet).
  Future<void> withdraw(Listing l) async {
    final prefs = await SharedPreferences.getInstance();
    if (l.pending) {
      await prefs.setString(_pendingKey,
          jsonEncode([for (final j in _decodeList(prefs.getString(_pendingKey))) if (j['id'] != l.id) j]));
      return;
    }
    await _ensureDeviceId();
    try {
      await _dio.delete('/api/listings/${l.id}');
    } on DioException catch (e) {
      throw PurchaseException(_message(e));
    }
    await refresh();
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the AgriEdge server. ${describeSyncError(e)}';
  }

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map>().map((m) => m.cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }
}

String _qty(double q) => q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toString();

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(MarketplaceRepository.new);

final listingsProvider = FutureProvider<ListingsView>((ref) => ref.watch(marketplaceRepositoryProvider).load());
