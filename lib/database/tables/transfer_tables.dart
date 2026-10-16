import 'package:drift/drift.dart';

class TransferRecords extends Table {
  TextColumn get id => text()();
  TextColumn get direction => text()(); // 'outgoing', 'incoming'
  TextColumn get transport => text()(); // 'localNetwork', 'bluetooth', 'cloud'
  TextColumn get status => text()(); // 'idle', 'queued', 'running', etc.
  Int64Column get totalBytes => int64()();
  Int64Column get transferredBytes => int64().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get errorCode => text().nullable()();
  TextColumn get peerName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransferItems extends Table {
  TextColumn get id => text()();
  TextColumn get transferId => text().references(TransferRecords, #id)();
  TextColumn get displayName => text()();
  Int64Column get expectedSize => int64()();
  TextColumn get savedPath => text().nullable()();
  TextColumn get expectedSha256 => text().nullable()();
  TextColumn get actualSha256 => text().nullable()();
  TextColumn get verificationStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class RecentFiles extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  Int64Column get fileSizeBytes => int64()();
  DateTimeColumn get accessedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
