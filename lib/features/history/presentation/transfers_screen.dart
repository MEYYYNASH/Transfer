import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/models/transfer_models.dart';

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  int _selectedFilter = 0; // 0: All, 1: Running, 2: Completed

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocale(locale);
    final transfers = ref.watch(transferQueueProvider);

    final filtered = transfers.where((item) {
      if (_selectedFilter == 1) {
        return item.status == TransferStatus.running ||
            item.status == TransferStatus.preparing ||
            item.status == TransferStatus.verifying;
      } else if (_selectedFilter == 2) {
        return item.status == TransferStatus.completed;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('transfers')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear completed',
            onPressed: () {
              ref.read(transferQueueProvider.notifier).clearCompleted();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(0, 'All (${transfers.length})'),
                const SizedBox(width: 8),
                _buildFilterChip(1, 'Active'),
                const SizedBox(width: 8),
                _buildFilterChip(2, 'Completed'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 48, color: AppColors.secondaryText),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('noTransfers'),
                          style: const TextStyle(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item.direction == TransferDirection.outgoing
                                          ? Icons.arrow_circle_up
                                          : Icons.arrow_circle_down,
                                      color: item.direction == TransferDirection.outgoing
                                          ? AppColors.primaryAccent
                                          : AppColors.secondaryAccent,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.peerName ?? 'Remote Device',
                                      style: const TextStyle(
                                        color: AppColors.mainText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildStatusBadge(item.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.progressPercentage / 100.0,
                                backgroundColor: AppColors.elevatedSurface,
                                valueColor: AlwaysStoppedAnimation(
                                  item.status == TransferStatus.completed
                                      ? AppColors.success
                                      : item.status == TransferStatus.failed
                                          ? AppColors.error
                                          : AppColors.primaryAccent,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(item.transferredBytes / (1024 * 1024)).toStringAsFixed(1)} / ${(item.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                ),
                                Text(
                                  '${item.progressPercentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AppColors.mainText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (item.errorCode != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Error: ${item.errorCode}',
                                style: const TextStyle(color: AppColors.error, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = index;
          });
        }
      },
      selectedColor: AppColors.primaryAccent.withOpacity(0.2),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryAccent : AppColors.secondaryText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryAccent : AppColors.cardBorder,
      ),
    );
  }

  Widget _buildStatusBadge(TransferStatus status) {
    Color color;
    switch (status) {
      case TransferStatus.completed:
        color = AppColors.success;
        break;
      case TransferStatus.failed:
        color = AppColors.error;
        break;
      case TransferStatus.running:
      case TransferStatus.verifying:
        color = AppColors.secondaryAccent;
        break;
      default:
        color = AppColors.secondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
