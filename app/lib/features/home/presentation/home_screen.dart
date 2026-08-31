import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../personalized_suggestions/data/personalized_suggestions_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _tiles = [
    _FeatureTile('Market Price', Icons.storefront, '/market-price'),
    _FeatureTile('MSP', Icons.price_check, '/msp'),
    _FeatureTile('Disease Prediction', Icons.camera_alt, '/disease-detection'),
    _FeatureTile('Soil Report', Icons.science, '/soil-report'),
    _FeatureTile('Crop Recommendation', Icons.agriculture, '/crop-recommendation'),
    _FeatureTile('Orders', Icons.shopping_cart, '/orders'),
    _FeatureTile('AI Assistant', Icons.smart_toy, '/assistant'),
    _FeatureTile('Disease Alerts', Icons.warning_amber_rounded, '/disease-alerts'),
    _FeatureTile('For You', Icons.recommend, '/suggestions'),
    _FeatureTile('Sync & Data', Icons.sync, '/sync-settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(personalizedSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AgriEdge')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((suggestions.value ?? []).isNotEmpty) ...[
            Text('For you', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...suggestions.value!.take(2).map(
                  (s) => Card(
                    child: ListTile(
                      leading: Icon(s.icon, color: Theme.of(context).colorScheme.primary),
                      title: Text(s.title),
                      subtitle: Text(s.description),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: _tiles.map((t) => _TileCard(tile: t)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile {
  const _FeatureTile(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _TileCard extends StatelessWidget {
  const _TileCard({required this.tile});
  final _FeatureTile tile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(tile.route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tile.icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(tile.label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
