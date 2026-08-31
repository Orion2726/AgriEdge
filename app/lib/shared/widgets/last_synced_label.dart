import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';

/// "Last updated 3 hours ago" pill, with a visible staleness warning once
/// past AppConstants.staleAfter — the offline-first spec requires cached
/// data to always show its age rather than pretend to be live.
class LastSyncedLabel extends StatelessWidget {
  const LastSyncedLabel({super.key, required this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lastSyncedAt == null) {
      return Text('Not yet synced', style: theme.textTheme.bodySmall);
    }
    final age = DateTime.now().difference(lastSyncedAt!);
    final isStale = age > AppConstants.staleAfter;
    final label = 'Last updated ${DateFormat.yMMMd().add_jm().format(lastSyncedAt!)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isStale ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          size: 14,
          color: isStale ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isStale ? theme.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}
