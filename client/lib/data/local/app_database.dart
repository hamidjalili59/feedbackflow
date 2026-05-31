import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class LocalForms extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get creatorId => text()();
  TextColumn get title => text()();
  TextColumn get status => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalFormFields extends Table {
  TextColumn get id => text()();
  TextColumn get formId => text()();
  TextColumn get fieldType => text()();
  TextColumn get label => text()();
  IntColumn get orderIndex => integer()();
  TextColumn get rawJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalSubmissions extends Table {
  TextColumn get id => text()();
  TextColumn get formId => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get submittedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalActivities extends Table {
  TextColumn get id => text()();
  TextColumn get organizationId => text()();
  TextColumn get title => text()();
  TextColumn get status => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalPermissions extends Table {
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    LocalForms,
    LocalFormFields,
    LocalSubmissions,
    LocalActivities,
    LocalPermissions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'feedbackflow',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
