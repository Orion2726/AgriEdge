import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'features/crop_recommendation/presentation/crop_recommendation_screen.dart';
import 'features/disease_alerts/presentation/disease_alerts_screen.dart';
import 'features/disease_detection/presentation/disease_detection_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/market_price/presentation/market_price_screen.dart';
import 'features/msp/presentation/msp_screen.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/personalized_suggestions/presentation/personalized_suggestions_screen.dart';
import 'features/soil_report/presentation/soil_report_screen.dart';
import 'features/sync_settings/presentation/sync_settings_screen.dart';
import 'sync_registration.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/market-price', builder: (context, state) => const MarketPriceScreen()),
    GoRoute(path: '/msp', builder: (context, state) => const MspScreen()),
    GoRoute(path: '/disease-detection', builder: (context, state) => const DiseaseDetectionScreen()),
    GoRoute(path: '/soil-report', builder: (context, state) => const SoilReportScreen()),
    GoRoute(path: '/crop-recommendation', builder: (context, state) => const CropRecommendationScreen()),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(path: '/assistant', builder: (context, state) => const AiAssistantScreen()),
    GoRoute(path: '/disease-alerts', builder: (context, state) => const DiseaseAlertsScreen()),
    GoRoute(path: '/suggestions', builder: (context, state) => const PersonalizedSuggestionsScreen()),
    GoRoute(path: '/sync-settings', builder: (context, state) => const SyncSettingsScreen()),
  ],
);

class AgriEdgeApp extends ConsumerWidget {
  const AgriEdgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force sync-job registration once at startup.
    ref.watch(syncRegistrationProvider);

    return MaterialApp.router(
      title: 'AgriEdge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
