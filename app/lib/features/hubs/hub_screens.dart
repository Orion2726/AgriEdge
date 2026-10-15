import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/live_feeds.dart';
import '../../shared/widgets/ui.dart';

class CropCareScreen extends StatelessWidget {
  const CropCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crops')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ActionTile(
            icon: Icons.camera_alt_outlined,
            title: 'Check a sick plant',
            subtitle: 'Take a leaf photo — works without internet',
            onTap: () => context.push('/disease-detection'),
          ),
          ActionTile(
            icon: Icons.science_outlined,
            title: 'Soil test report',
            subtitle: 'Enter your soil card values',
            onTap: () => context.push('/soil-report'),
          ),
          ActionTile(
            icon: Icons.eco_outlined,
            title: 'What should I grow?',
            subtitle: 'Crop suggestions from your soil test',
            onTap: () => context.push('/crop-recommendation'),
          ),
          ActionTile(
            icon: Icons.recommend_outlined,
            title: 'Tips for you',
            subtitle: 'Sowing windows and advice from your data',
            onTap: () => context.push('/suggestions'),
          ),
          ActionTile(
            icon: Icons.forum_outlined,
            title: 'Farming questions',
            subtitle: 'Answers from a curated farming FAQ',
            onTap: () => context.push('/assistant'),
          ),
        ],
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ActionTile(
            icon: Icons.shopping_basket_outlined,
            title: 'Farm supplies',
            subtitle: 'Buy and sell seed, fertiliser, tools and produce',
            onTap: () => context.push('/orders'),
          ),
          ActionTile(
            icon: Icons.price_check,
            title: 'Minimum support prices',
            subtitle: 'Government MSP for major crops',
            onTap: () => context.push('/msp'),
          ),
          ActionTile(
            icon: Icons.sync,
            title: 'Sync & server',
            subtitle: 'Connection to the AgriEdge server, models',
            onTap: () => context.push('/sync-settings'),
          ),
          ActionTile(
            icon: Icons.info_outline,
            title: 'About & data sources',
            subtitle: 'Where the information in this app comes from',
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget src(String name, String what, String url) => Card(
          child: ListTile(
            title: Text(name),
            subtitle: Text(what),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('About & data sources')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SectionHeader('Live sources (free, no account)'),
          src('Open-Meteo', 'Weather forecast, topsoil moisture and crop water use · CC BY 4.0', 'https://open-meteo.com'),
          for (final e in newsSources.entries) src(e.key, 'News headlines via public RSS · links open the original', e.value),
          const SectionHeader('Through the AgriEdge server'),
          src('Mandi prices — Agmarknet',
              'Daily wholesale prices via data.gov.in (when the server has a key) or the open Mandi Price API '
                  '(CC BY-NC-SA 4.0). The server fetches every 3 hours; phones without internet get them over Bluetooth.',
              'https://www.data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi'),
          src('Minimum Support Price', 'Kharif 2026-27 and Rabi 2027-28 MSP announced by the Government of India (CCEA).',
              'https://www.pib.gov.in'),
          const Card(
            child: ListTile(
              title: Text('Farm supplies'),
              subtitle: Text('Listings from farmers and the AgriEdge store. Urea and DAP are government-fixed MRPs; '
                  'other store prices are typical retail prices. Buying needs a connection to the server.'),
            ),
          ),
          const SectionHeader('On this phone'),
          const Card(
            child: ListTile(
              title: Text('Disease detection & crop advice'),
              subtitle: Text('Trained models run on the phone — no internet needed.'),
            ),
          ),
          const Card(
            child: ListTile(
              title: Text('Nearby alerts'),
              subtitle: Text(
                  'Farmer reports shared phone-to-phone over Bluetooth. Each report is signed by the phone that made it; '
                  'the signature proves which phone sent it, not that the diagnosis is correct.'),
            ),
          ),
        ],
      ),
    );
  }
}
