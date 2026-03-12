import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/i_client_repository.dart';
import '../local/database.dart';
import '../remote/models/client_firestore_model.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ClientRepository(db);
});

class ClientRepository implements IClientRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ClientRepository(this._db);

  @override
  Future<List<ClientEntity>> getClients() async {
    final localClients = await _db.select(_db.clients).get();
    return localClients
        .map(
          (c) => ClientEntity(
            id: c.id,
            name: c.name,
            phone: c.phone,
            email: c.email,
            address: c.address,
            totalQuotes: c.totalQuotes,
            totalValue: c.totalValue,
            createdAt: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
          ),
        )
        .toList();
  }

  @override
  Stream<List<ClientEntity>> watchClients() {
    return _db
        .select(_db.clients)
        .watch()
        .map(
          (localClients) => localClients
              .map(
                (c) => ClientEntity(
                  id: c.id,
                  name: c.name,
                  phone: c.phone,
                  email: c.email,
                  address: c.address,
                  totalQuotes: c.totalQuotes,
                  totalValue: c.totalValue,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<ClientEntity?> getClientById(String id) async {
    final result = await (_db.select(
      _db.clients,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (result == null) return null;
    return ClientEntity(
      id: result.id,
      name: result.name,
      phone: result.phone,
      email: result.email,
      address: result.address,
      totalQuotes: result.totalQuotes,
      totalValue: result.totalValue,
      createdAt: DateTime.fromMillisecondsSinceEpoch(result.createdAt),
    );
  }

  @override
  Future<void> createClient(ClientEntity client) async {
    // 1. Write to local SQLite
    await _db
        .into(_db.clients)
        .insert(
          ClientsCompanion.insert(
            id: client.id,
            name: client.name,
            phone: Value(client.phone),
            email: Value(client.email),
            address: Value(client.address),
            totalQuotes: Value(client.totalQuotes),
            totalValue: Value(client.totalValue),
            createdAt: client.createdAt.millisecondsSinceEpoch,
            isSynced: const Value(false),
          ),
        );

    // 2. Sync to Firestore
    _syncToFirestore(client);
  }

  @override
  Future<void> updateClient(ClientEntity client) async {
    await (_db.update(_db.clients)..where((c) => c.id.equals(client.id))).write(
      ClientsCompanion(
        name: Value(client.name),
        phone: Value(client.phone),
        email: Value(client.email),
        address: Value(client.address),
        totalQuotes: Value(client.totalQuotes),
        totalValue: Value(client.totalValue),
        isSynced: const Value(false),
      ),
    );
    _syncToFirestore(client);
  }

  @override
  Future<void> deleteClient(String id) async {
    await (_db.delete(_db.clients)..where((c) => c.id.equals(id))).go();
    try {
      await _firestore.collection('clients').doc(id).delete();
    } catch (_) {
      // Offline fallback handling omitted for brevity
    }
  }

  @override
  Future<void> syncUnsyncedClients() async {
    final unsynced = await (_db.select(
      _db.clients,
    )..where((c) => c.isSynced.equals(false))).get();
    for (var c in unsynced) {
      final entity = await getClientById(c.id);
      if (entity != null) _syncToFirestore(entity);
    }
  }

  void _syncToFirestore(ClientEntity client) async {
    try {
      final model = ClientFirestoreModel.fromEntity(client);
      await _firestore.collection('clients').doc(client.id).set(model.toJson());

      await (_db.update(_db.clients)..where((c) => c.id.equals(client.id)))
          .write(const ClientsCompanion(isSynced: Value(true)));
    } catch (e) {
      await (_db.update(_db.clients)..where((c) => c.id.equals(client.id)))
          .write(const ClientsCompanion(isSynced: Value(false)));
    }
  }
}
