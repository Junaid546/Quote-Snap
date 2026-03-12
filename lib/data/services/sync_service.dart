import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/database.dart';
import 'package:drift/drift.dart' hide Column;

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db);
  ref.onDispose(service.dispose);
  return service;
});

// ─── Sync Status Enum ─────────────────────────────────────────────────────────
enum SyncStatus { idle, syncing, success, error }

class SyncService {
  final AppDatabase _db;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Callbacks for UI provider
  void Function(SyncStatus, int)? onStatusChanged;

  SyncService(this._db);

  Future<void> initialize() async {
    // Listen for connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );
      if (isOnline) {
        debugPrint('[SyncService] Network restored — triggering sync');
        triggerSync();
      }
    });

    // Initial check on app start
    final results = await Connectivity().checkConnectivity();
    final isConnected = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
    if (isConnected) triggerSync();
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    onStatusChanged?.call(SyncStatus.syncing, 0);

    try {
      await syncUserProfile();
      await syncClients();
      await syncQuotes();
      _lastSyncTime = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSyncTime', _lastSyncTime!.millisecondsSinceEpoch);

      onStatusChanged?.call(SyncStatus.success, 0);
      debugPrint('[SyncService] Sync complete at $_lastSyncTime');
    } catch (e) {
      debugPrint('[SyncService] Sync failed: $e');
      onStatusChanged?.call(SyncStatus.error, 0);
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Sync Quotes ────────────────────────────────────────────────────────────
  Future<void> syncQuotes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // CONFLICT RESOLUTION: local-wins strategy.
    // SQLite is the source of truth. Firestore is the backup/sync layer.
    // TODO: Implement last-write-wins with updatedAt comparison in Phase 2.

    final unsynced = await (_db.select(
      _db.quotes,
    )..where((t) => t.isSynced.equals(false))).get();

    if (unsynced.isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    // Split into chunks of 500 operations (Firestore batch limit)
    final chunks = _chunk(unsynced, 500);

    for (final chunk in chunks) {
      final batch = firestore.batch();

      for (final q in chunk) {
        final qRef = firestore
            .collection('users')
            .doc(uid)
            .collection('quotes')
            .doc(q.id);
        batch.set(qRef, {
          'id': q.id,
          'quoteNumber': q.quoteNumber,
          'clientId': q.clientId,
          'clientName': q.clientName,
          'jobType': q.jobType,
          'jobAddress': q.jobAddress,
          'notes': q.notes,
          'laborHours': q.laborHours,
          'laborRate': q.laborRate,
          'taxRate': q.taxRate,
          'applyTax': q.applyTax,
          'status': q.status,
          'totalAmount': q.totalAmount,
          'createdAt': q.createdAt,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));

        // Also sync its items
        final items = await (_db.select(
          _db.quoteItems,
        )..where((t) => t.quoteId.equals(q.id))).get();
        for (final item in items) {
          final itemRef = qRef.collection('items').doc(item.id);
          batch.set(itemRef, {
            'id': item.id,
            'name': item.name,
            'unitPrice': item.unitPrice,
            'quantity': item.quantity,
            'isChecked': item.isChecked,
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();

      // Mark as synced in SQLite
      for (final q in chunk) {
        await (_db.update(_db.quotes)..where((t) => t.id.equals(q.id))).write(
          const QuotesCompanion(isSynced: Value(true)),
        );
      }
    }

    debugPrint('[SyncService] Synced ${unsynced.length} quotes');
  }

  // ─── Sync Clients ────────────────────────────────────────────────────────────
  Future<void> syncClients() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final unsynced = await (_db.select(
      _db.clients,
    )..where((t) => t.isSynced.equals(false))).get();

    if (unsynced.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final chunks = _chunk(unsynced, 500);

    for (final chunk in chunks) {
      final batch = firestore.batch();
      for (final c in chunk) {
        final ref = firestore
            .collection('users')
            .doc(uid)
            .collection('clients')
            .doc(c.id);
        batch.set(ref, {
          'id': c.id,
          'name': c.name,
          'phone': c.phone,
          'email': c.email,
          'address': c.address,
          'totalQuotes': c.totalQuotes,
          'totalValue': c.totalValue,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
      await batch.commit();

      for (final c in chunk) {
        await (_db.update(_db.clients)..where((t) => t.id.equals(c.id))).write(
          const ClientsCompanion(isSynced: Value(true)),
        );
      }
    }

    debugPrint('[SyncService] Synced ${unsynced.length} clients');
  }

  // ─── Sync User Profile ───────────────────────────────────────────────────────
  Future<void> syncUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.id.equals(uid))).getSingleOrNull();

    if (row == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'businessName': row.businessName,
      'ownerName': row.ownerName,
      'email': row.email,
      'phone': row.phone,
      'licenseNumber': row.licenseNumber,
      'logoPath': row.logoPath,
      'defaultHourlyRate': row.defaultHourlyRate,
      'defaultTaxRate': row.defaultTaxRate,
      'subscriptionPlan': row.subscriptionPlan,
      'subscriptionRenewal': row.subscriptionRenewal,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('[SyncService] User profile synced');
  }

  // ─── Pro-only Real-time Listener ─────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _remoteListener;

  void listenToRemoteChanges(String uid) {
    // Only for Pro subscribers
    _remoteListener?.cancel();
    _remoteListener = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quotes')
        .snapshots()
        .listen((snap) async {
          for (final change in snap.docChanges) {
            if (change.type == DocumentChangeType.modified) {
              final remote = change.doc.data();
              if (remote == null) continue;

              final localUpdatedAt = await (_db.select(
                _db.quotes,
              )..where((t) => t.id.equals(change.doc.id))).getSingleOrNull();

              final remoteUpdatedAt = (remote['updatedAt'] as int?) ?? 0;
              final localTs = localUpdatedAt?.updatedAt ?? 0;

              // Local wins: only update if remote is newer
              if (remoteUpdatedAt > localTs) {
                // TODO: Map remote fields back to SQLite Companion — Phase 2
                debugPrint(
                  '[SyncService] Remote quote ${change.doc.id} is newer, updating locally...',
                );
              }
            }
          }
        });
  }

  void stopListening() => _remoteListener?.cancel();

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _remoteListener?.cancel();
  }
}
