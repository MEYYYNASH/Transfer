import 'package:drift/drift.dart';

class TrustedDevices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get ipAddress => text().nullable()();
  TextColumn get publicKeyFingerprint => text().nullable()();
  BoolColumn get isAutoAccept => boolean().withDefault(const Constant(false))();
  DateTimeColumn get pairedAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

class PairingSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get peerName => text()();
  TextColumn get peerIp => text()();
  TextColumn get oneTimePin => text()();
  DateTimeColumn get expiresAt => dateTime()();
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {sessionId};
}

class UpdateHistory extends Table {
  TextColumn get version => text()();
  TextColumn get releaseTitle => text()();
  TextColumn get downloadUrl => text()();
  TextColumn get sha256Checksum => text()();
  TextColumn get installStatus => text()(); // 'downloaded', 'verified', 'installed', 'failed'
  DateTimeColumn get appliedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {version};
}

class AppSettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
