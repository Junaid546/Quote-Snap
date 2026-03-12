import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

class Quotes extends Table {
  TextColumn get id => text()();
  IntColumn get quoteNumber => integer().autoIncrement()();
  TextColumn get clientId => text()();
  TextColumn get clientName => text()();
  TextColumn get jobType => text()();
  TextColumn get jobAddress => text()();
  TextColumn get photosPaths => text()(); // JSON array stored as string
  TextColumn get voiceNotePath => text().nullable()();
  TextColumn get notes => text()();
  RealColumn get laborHours => real()();
  RealColumn get laborRate => real()();
  RealColumn get taxRate => real()();
  BoolColumn get applyTax => boolean()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  RealColumn get totalAmount => real()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class QuoteItems extends Table {
  TextColumn get id => text()();
  TextColumn get quoteId => text()(); // Foreign key manually managed
  TextColumn get name => text()();
  RealColumn get unitPrice => real()();
  IntColumn get quantity => integer()();
  BoolColumn get isChecked => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get totalQuotes => integer().withDefault(const Constant(0))();
  RealColumn get totalValue => real().withDefault(const Constant(0.0))();
  IntColumn get createdAt => integer()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class UserProfile extends Table {
  TextColumn get id => text()();
  TextColumn get businessName => text()();
  TextColumn get ownerName => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get licenseNumber => text()();
  TextColumn get logoPath => text().nullable()();
  RealColumn get defaultHourlyRate =>
      real().withDefault(const Constant(85.0))();
  RealColumn get defaultTaxRate => real().withDefault(const Constant(8.5))();
  TextColumn get subscriptionPlan =>
      text().withDefault(const Constant('free'))();
  TextColumn get subscriptionRenewal => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Quotes, QuoteItems, Clients, UserProfile])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
