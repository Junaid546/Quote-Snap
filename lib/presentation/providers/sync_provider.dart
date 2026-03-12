import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';
import '../../data/services/sync_service.dart';

// ─── Sync State ───────────────────────────────────────────────────────────────

class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int unsyncedCount;
  final SyncStatus status;

  const SyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.lastSyncTime,
    this.unsyncedCount = 0,
    this.status = SyncStatus.idle,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? unsyncedCount,
    SyncStatus? status,
  }) => SyncState(
    isOnline: isOnline ?? this.isOnline,
    isSyncing: isSyncing ?? this.isSyncing,
    lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    unsyncedCount: unsyncedCount ?? this.unsyncedCount,
    status: status ?? this.status,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SyncNotifier extends Notifier<SyncState> {
  late AppDatabase _db;
  late SyncService _service;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _successTimer;

  @override
  SyncState build() {
    _db = ref.watch(databaseProvider);
    _service = ref.watch(syncServiceProvider);

    // Wire up callbacks from SyncService
    _service.onStatusChanged = _onServiceStatusChanged;

    // Connectivity watcher
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );
      _updateOnlineStatus(online);
    });

    ref.onDispose(() {
      _connSub?.cancel();
      _successTimer?.cancel();
    });

    // Initial connectivity check + load saved lastSyncTime
    _init();

    return const SyncState();
  }

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );

    final prefs = await SharedPreferences.getInstance();
    final lastTs = prefs.getInt('lastSyncTime');
    final lastSync = lastTs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastTs)
        : null;

    final unsynced = await _countUnsynced();
    state = state.copyWith(
      isOnline: online,
      lastSyncTime: lastSync,
      unsyncedCount: unsynced,
    );
  }

  void _onServiceStatusChanged(SyncStatus status, int count) async {
    final unsynced = await _countUnsynced();

    if (status == SyncStatus.success) {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('lastSyncTime');
      final lastSync = ts != null
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now();
      state = state.copyWith(
        status: SyncStatus.success,
        unsyncedCount: unsynced,
        lastSyncTime: lastSync,
        isSyncing: false,
      );

      // Auto-hide success after 3 seconds
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(seconds: 3), () {
        if (state.status == SyncStatus.success) {
          state = state.copyWith(status: SyncStatus.idle);
        }
      });
    } else {
      state = state.copyWith(
        status: status,
        isSyncing: status == SyncStatus.syncing,
        unsyncedCount: unsynced,
      );
    }
  }

  void _updateOnlineStatus(bool online) {
    state = state.copyWith(isOnline: online);
  }

  Future<int> _countUnsynced() async {
    final q = await (_db.select(
      _db.quotes,
    )..where((t) => t.isSynced.equals(false))).get();
    final c = await (_db.select(
      _db.clients,
    )..where((t) => t.isSynced.equals(false))).get();
    return q.length + c.length;
  }

  Future<void> triggerManualSync() async {
    await _service.triggerSync();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  () => SyncNotifier(),
);
