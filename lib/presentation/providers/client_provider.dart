import 'dart:async';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';
import '../../data/repositories/client_repository.dart';
import '../../domain/entities/client_entity.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class ClientState {
  final List<ClientEntity> allClients;
  final List<ClientEntity> filteredClients;
  final Map<String, List<ClientEntity>> groupedClients;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ClientState({
    this.allClients = const [],
    this.filteredClients = const [],
    this.groupedClients = const {},
    this.searchQuery = '',
    this.isLoading = true,
    this.error,
  });

  ClientState copyWith({
    List<ClientEntity>? allClients,
    List<ClientEntity>? filteredClients,
    Map<String, List<ClientEntity>>? groupedClients,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClientState(
      allClients: allClients ?? this.allClients,
      filteredClients: filteredClients ?? this.filteredClients,
      groupedClients: groupedClients ?? this.groupedClients,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ClientNotifier extends StateNotifier<ClientState> {
  final AppDatabase _db;
  final ClientRepository _repo;

  StreamSubscription<List<ClientEntity>>? _sub;
  Timer? _debounce;

  ClientNotifier(this._db, this._repo) : super(const ClientState()) {
    _startWatching();
  }

  void _startWatching() {
    state = state.copyWith(isLoading: true);
    _sub = _repo.watchClients().listen(
      (clients) {
        final sorted = [...clients]..sort((a, b) => a.name.compareTo(b.name));
        final filtered = _applySearch(sorted, state.searchQuery);
        state = state.copyWith(
          allClients: sorted,
          filteredClients: filtered,
          groupedClients: _group(filtered),
          isLoading: false,
          clearError: true,
        );
      },
      onError: (e) =>
          state = state.copyWith(isLoading: false, error: e.toString()),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Search (debounced 300ms) ──────────────────────────────────────────────────

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final filtered = _applySearch(state.allClients, query);
      state = state.copyWith(
        searchQuery: query,
        filteredClients: filtered,
        groupedClients: _group(filtered),
      );
    });
  }

  List<ClientEntity> _applySearch(List<ClientEntity> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.toLowerCase().contains(q) ?? false) ||
          (c.email?.toLowerCase().contains(q) ?? false) ||
          (c.address?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── Group by Letter ───────────────────────────────────────────────────────────

  Map<String, List<ClientEntity>> _group(List<ClientEntity> clients) {
    final map = <String, List<ClientEntity>>{};
    for (final c in clients) {
      final first = c.name.isNotEmpty ? c.name[0].toUpperCase() : '#';
      final key = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
      map.putIfAbsent(key, () => []).add(c);
    }
    // Sort keys alphabetically, '#' goes last
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) {
        if (a.key == '#') return 1;
        if (b.key == '#') return -1;
        return a.key.compareTo(b.key);
      }),
    );
    return sorted;
  }

  // ── Add Client ────────────────────────────────────────────────────────────────

  /// Returns the saved [ClientEntity] or null on validation failure.
  Future<ClientEntity?> addClient({
    required String name,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? tradeType,
  }) async {
    // Validation
    if (name.trim().length < 2) {
      state = state.copyWith(error: 'Name must be at least 2 characters.');
      return null;
    }
    if (email != null && email.trim().isNotEmpty) {
      final emailRx = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
      if (!emailRx.hasMatch(email.trim())) {
        state = state.copyWith(error: 'Enter a valid email address.');
        return null;
      }
    }
    if (phone != null && phone.trim().isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 7) {
        state = state.copyWith(
          error: 'Phone number must be at least 7 digits.',
        );
        return null;
      }
    }

    // Duplicate check (name + phone combo)
    final trimmedName = name.trim().toLowerCase();
    final duplicate = state.allClients.any(
      (c) =>
          c.name.toLowerCase() == trimmedName &&
          (phone == null ||
              phone.isEmpty ||
              c.phone == null ||
              c.phone == phone.trim()),
    );
    if (duplicate) {
      state = state.copyWith(
        error: 'A client with this name and phone already exists.',
      );
      return null;
    }

    final entity = ClientEntity(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      address: address?.trim().isEmpty == true ? null : address?.trim(),
      totalQuotes: 0,
      totalValue: 0.0,
      createdAt: DateTime.now(),
    );

    await _repo.createClient(entity);
    state = state.copyWith(clearError: true);
    return entity;
  }

  // ── Update Client ─────────────────────────────────────────────────────────────

  Future<bool> updateClient(ClientEntity client) async {
    try {
      await _repo.updateClient(client);
      state = state.copyWith(clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Update failed: $e');
      return false;
    }
  }

  // ── Delete Client ─────────────────────────────────────────────────────────────

  /// Returns the quote count for the warning dialog (0 = no warning needed).
  Future<int> getClientQuoteCount(String clientId) async {
    final result = await _db
        .customSelect(
          'SELECT COUNT(*) as c FROM quotes WHERE client_id = ?',
          variables: [Variable.withString(clientId)],
        )
        .getSingleOrNull();
    return (result?.data['c'] as int? ?? 0);
  }

  Future<void> deleteClient(String id) async {
    await _repo.deleteClient(id);
    state = state.copyWith(clearError: true);
  }

  // ── Recalculate Client Stats ──────────────────────────────────────────────────

  Future<void> recalculateClientStats(String clientId) async {
    try {
      // Total quotes count
      final countRes = await _db
          .customSelect(
            'SELECT COUNT(*) as c FROM quotes WHERE client_id = ?',
            variables: [Variable.withString(clientId)],
          )
          .getSingleOrNull();
      final totalQuotes = countRes?.data['c'] as int? ?? 0;

      // Total accepted value
      final valueRes = await _db
          .customSelect(
            "SELECT COALESCE(SUM(total_amount), 0) as s FROM quotes WHERE client_id = ? AND status = 'accepted'",
            variables: [Variable.withString(clientId)],
          )
          .getSingleOrNull();
      final totalValue = (valueRes?.data['s'] as num? ?? 0).toDouble();

      await (_db.update(
        _db.clients,
      )..where((c) => c.id.equals(clientId))).write(
        ClientsCompanion(
          totalQuotes: Value(totalQuotes),
          totalValue: Value(totalValue),
          isSynced: const Value(false),
        ),
      );

      // Async Firestore sync
      final client = await _repo.getClientById(clientId);
      if (client != null) _repo.updateClient(client);
    } catch (_) {}
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final repo = ref.watch(clientRepositoryProvider);
  return ClientNotifier(db, repo);
});

// ─── Single Client Stream Provider ───────────────────────────────────────────

final watchClientProvider = StreamProvider.family<ClientEntity?, String>((
  ref,
  id,
) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.clients,
  )..where((c) => c.id.equals(id))).watchSingleOrNull().map(
    (row) => row == null
        ? null
        : ClientEntity(
            id: row.id,
            name: row.name,
            phone: row.phone,
            email: row.email,
            address: row.address,
            totalQuotes: row.totalQuotes,
            totalValue: row.totalValue,
            createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
          ),
  );
});
