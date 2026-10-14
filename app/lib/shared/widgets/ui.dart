import 'package:flutter/material.dart';

/// Small shared building blocks so every screen looks and behaves alike.

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 0, 6),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ?action,
        ]),
      );
}

/// Empty / offline / error state with an optional retry.
class StateMessage extends StatelessWidget {
  const StateMessage({super.key, required this.icon, required this.text, this.onRetry, this.compact = false});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 32, horizontal: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: compact ? 28 : 44, color: theme.colorScheme.outline),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ],
      ]),
    );
  }
}

/// Pill showing where data came from and how old it is.
class SourceTag extends StatelessWidget {
  const SourceTag({super.key, required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warning ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: warning ? scheme.onTertiaryContainer : scheme.onSurfaceVariant)),
    );
  }
}

/// Big tappable action tile used on hubs and the dashboard.
class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}
