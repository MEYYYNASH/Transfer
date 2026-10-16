import 'package:drift/drift.dart';

class UploadQueue extends Table {
  TextColumn get id => text()();
  TextColumn get localFilePath => text()();
  TextColumn get originalName => text()();
  Int64Column get fileSizeBytes => int64()();
  TextColumn get status => text()(); // 'queued', 'uploading', 'completed', 'failed'
  TextColumn get uploadId => text().nullable()();
  TextColumn get shareToken => text().nullable()();
  Int64Column get uploadedBytes => int64().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DownloadQueue extends Table {
  TextColumn get id => text()();
  TextColumn get shareToken => text()();
  TextColumn get fileName => text()();
  Int64Column get expectedSizeBytes => int64()();
  TextColumn get targetSavePath => text()();
  TextColumn get status => text()(); // 'queued', 'downloading', 'verifying', 'completed', 'failed'
  Int64Column get downloadedBytes => int64().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SavedShareLinks extends Table {
  TextColumn get id => text()();
  TextColumn get shareToken => text()();
  TextColumn get fileName => text()();
  Int64Column get fileSizeBytes => int64()();
  TextColumn get directUrl => text()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  IntColumn get maxDownloads => integer().nullable()();
  IntColumn get currentDownloads => integer().withDefault(const Constant(0))();
  BoolColumn get isRevoked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
