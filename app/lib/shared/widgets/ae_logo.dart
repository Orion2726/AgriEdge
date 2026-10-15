import 'package:flutter/material.dart';

/// The AgriEdge mark: the Æ ligature — A and E fused, as in Agri·Edge.
class AeMark extends StatelessWidget {
  const AeMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3E9A44), Color(0xFF14451A)],
          ),
        ),
        child: Text(
          'Æ',
          style: TextStyle(
            fontFamily: 'JetBrainsMonoNerd',
            fontWeight: FontWeight.w800,
            fontSize: size * 0.56,
            height: 1,
            color: const Color(0xFFF3F8EE),
          ),
        ),
      );
}

/// Centred wordmark for the home app bar.
class AeWordmark extends StatelessWidget {
  const AeWordmark({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AeMark(size: 30),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Agri'),
              TextSpan(text: 'Edge', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ]),
            style: TextStyle(
              fontFamily: 'JetBrainsMonoNerd',
              fontWeight: FontWeight.w800,
              fontSize: 23,
              letterSpacing: -0.8,
              height: 1,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      );
}
