import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/transfer_tables.dart';
import 'tables/queue_tables.dart';
import 'tables/security_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  TransferRecords,
  TransferItems,
  RecentFiles,
  UploadQueue,
  DownloadQueue,
  SavedShareLinks,
  TrustedDevices,
  PairingSessions,
  UpdateHistory,
  AppSettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Schema migrations handling
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'linkora_data.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
