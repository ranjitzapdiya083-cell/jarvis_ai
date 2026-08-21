import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../history/domain/history_entry.dart';

class RecentCommandsList extends StatelessWidget {
  final List<HistoryEntry> entries;
  final VoidCallback onSeeAll;

  const RecentCommandsList({super.key, required this.entries, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Commands', style: Theme.of(context).textTheme.titleMedium),
            TextButton(onPressed: onSeeAll, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Abhi tak koi command history nahi hai — mic dabao aur kuch bolo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ...entries.map((e) => _HistoryTile(entry: e)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryTile({required this.entry});

  IconData get _icon {
    switch (entry.intentType) {
      case 'call':
        return Icons.call;
      case 'sendMessage':
        return Icons.chat_bubble;
      case 'screenOff':
        return Icons.lock;
      case 'getBattery':
        return Icons.battery_full;
      case 'torchOn':
      case 'torchOff':
        return Icons.flashlight_on;
      case 'openApp':
        return Icons.apps;
      default:
        return Icons.mic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (entry.success ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 18, color: entry.success ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.rawText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(DateFormat('hh:mm a').format(entry.timestamp), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
