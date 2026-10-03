import 'package:agriedge/features/market_price/data/market_price_repository.dart';
import 'package:agriedge/features/market_price/domain/market_price_entry.dart';
import 'package:agriedge/features/market_price/ml/price_forecast_ml_service.dart';
import 'package:agriedge/features/market_price/ml/price_forecast_model_manager.dart';
import 'package:agriedge/features/market_price/presentation/market_price_screen.dart';
import 'package:agriedge/features/msp/data/msp_repository.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePriceForecastMlService extends PriceForecastMlService {
  _FakePriceForecastMlService() : super(PriceForecastModelManager(Dio()));

  @override
  Future<List<DayForecast>?> forecast({
    required String commodity,
    required double todayPrice,
    required DateTime asOf,
  }) async {
    return List.generate(
      7,
      (i) => DayForecast(
        price: todayPrice + i * 2,
        lowerBound: todayPrice - 50,
        upperBound: todayPrice + 50 + i * 10,
      ),
    );
  }
}

void main() {
  testWidgets('tapping a commodity opens a chart, not a list', (tester) async {
    final entry = MarketPriceEntry(
      commodity: 'Wheat',
      mandi: 'Test Mandi',
      pricePerQuintal: 2450,
      priceDate: DateTime(2026, 1, 1),
      fetchedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketPricesProvider.overrideWith((ref) => Stream.value([entry])),
          marketPriceLastSyncedProvider.overrideWith((ref) => Future.value(null)),
          mspRatesProvider.overrideWith((ref) => Stream.value(const [])),
          priceForecastMlServiceProvider.overrideWithValue(_FakePriceForecastMlService()),
        ],
        child: const MaterialApp(home: MarketPriceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wheat'), findsOneWidget);

    await tester.tap(find.text('Wheat'));
    await tester.pumpAndSettle();

    // The forecast is a chart (LineChart), not the old list-of-rows UI.
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Wheat — 7-day outlook'), findsOneWidget);
    expect(find.text('Estimate'), findsOneWidget);
    expect(find.text('Typical range'), findsOneWidget);
  });
}
