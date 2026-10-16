import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_locale.dart';
import '../../services/networking/local_network_service.dart';
import '../../services/networking/cloud_transfer_service.dart';
import '../../features/updates/data/update_repository.dart';
import '../models/transfer_models.dart';

// Locale Provider (en vs km)
final localeProvider = StateProvider<Locale>((ref) => AppLocale.enLocale);

// Theme Provider (Dark vs AMOLED)
enum ThemeOption { dark, amoled }
final themeOptionProvider = StateProvider<ThemeOption>((ref) => ThemeOption.dark);

// Active Transfers StateNotifier
class TransferQueueNotifier extends StateNotifier<List<TransferRecordModel>> {
  TransferQueueNotifier() : super([]);

  void updateRecord(TransferRecordModel record) {
    state = [
      for (final item in state)
        if (item.id == record.id) record else item,
      if (!state.any((item) => item.id == record.id)) record,
    ];
  }

  void removeRecord(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearCompleted() {
    state = state
        .where((item) =>
            item.status != TransferStatus.completed &&
            item.status != TransferStatus.cancelled &&
            item.status != TransferStatus.failed)
        .toList();
  }
}

final transferQueueProvider =
    StateNotifierProvider<TransferQueueNotifier, List<TransferRecordModel>>((ref) {
  return TransferQueueNotifier();
});

// Singletons
final localNetworkServiceProvider = Provider<LocalNetworkService>((ref) {
  return LocalNetworkService();
});

final cloudTransferServiceProvider = Provider<CloudTransferService>((ref) {
  return CloudTransferService(baseUrl: 'http://127.0.0.1:8000');
});

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  return UpdateRepository();
});
