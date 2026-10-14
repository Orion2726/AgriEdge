import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'features/crop_recommendation/presentation/crop_recommendation_screen.dart';
import 'features/disease_alerts/presentation/disease_alerts_screen.dart';
import 'features/disease_detection/presentation/disease_detection_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/hubs/hub_screens.dart';
import 'features/market_price/presentation/market_price_screen.dart';
import 'features/msp/presentation/msp_screen.dart';
import 'features/orders/presentation/orders_screen.dart';
import 'features/personalized_suggestions/presentation/personalized_suggestions_screen.dart';
import 'features/soil_report/presentation/soil_report_screen.dart';
import 'features/sync_settings/presentation/sync_settings_screen.dart';
import 'sync_registration.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRoute _page(String path, Widget child) =>
    GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (context, state) => child);

final _router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _TabShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/market', builder: (c, s) => const MarketPriceScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/care', builder: (c, s) => const CropCareScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/nearby', builder: (c, s) => const DiseaseAlertsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (c, s) => const MoreScreen())]),
      ],
    ),
    _page('/msp', const MspScreen()),
    _page('/disease-detection', const DiseaseDetectionScreen()),
    _page('/soil-report', const SoilReportScreen()),
    _page('/crop-recommendation', const CropRecommendationScreen()),
    _page('/orders', const OrdersScreen()),
    _page('/assistant', const AiAssistantScreen()),
    _page('/suggestions', const PersonalizedSuggestionsScreen()),
    _page('/sync-settings', const SyncSettingsScreen()),
    _page('/about', const AboutScreen()),
    GoRoute(path: '/disease-alerts', redirect: (c, s) => '/nearby'),
    GoRoute(path: '/market-price', redirect: (c, s) => '/market'),
  ],
);

class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      // Tab labels are capped at 1.15× so five tabs still fit when the phone
      // uses a large system font; screen content keeps the user's full size.
      bottomNavigationBar: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
        ),
        child: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Market'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), selectedIcon: Icon(Icons.spa), label: 'Crops'),
          NavigationDestination(icon: Icon(Icons.wifi_tethering), selectedIcon: Icon(Icons.wifi_tethering), label: 'Nearby'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
        ),
      ),
    );
  }
}

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
