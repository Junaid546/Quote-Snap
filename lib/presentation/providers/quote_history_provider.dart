import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';
import '../../data/repositories/client_repository.dart';
import '../../data/repositories/quote_repository.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/entities/quote_entity.dart';

// ─── Filter Enum ──────────────────────────────────────────────────────────────

enum QuoteHistoryFilter { all, pending, accepted, rejected }

// ─── State ────────────────────────────────────────────────────────────────────

class QuoteHistoryState {
  final List<QuoteEntity> allQuotes;
  final List<QuoteEntity> filteredQuotes;
  final QuoteHistoryFilter activeFilter;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const QuoteHistoryState({
    this.allQuotes = const [],
    this.filteredQuotes = const [],
    this.activeFilter = QuoteHistoryFilter.all,
    this.searchQuery = '',
    this.isLoading = true,
    this.error,
  });

  // ── Per-status counts (for tab badges) ──────────────────────────────────────
  int get countAll => allQuotes.length;
  int get countPending => allQuotes.where((q) => q.status == 'pending').length;
  int get countAccepted =>
      allQuotes.where((q) => q.status == 'accepted').length;
  int get countRejected =>
      allQuotes.where((q) => q.status == 'rejected').length;

  QuoteHistoryState copyWith({
    List<QuoteEntity>? allQuotes,
    List<QuoteEntity>? filteredQuotes,
    QuoteHistoryFilter? activeFilter,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return QuoteHistoryState(
      allQuotes: allQuotes ?? this.allQuotes,
      filteredQuotes: filteredQuotes ?? this.filteredQuotes,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class QuoteHistoryNotifier extends StateNotifier<QuoteHistoryState> {
  final AppDatabase _db;
  final QuoteRepository _quoteRepo;
  final ClientRepository _clientRepo;

  StreamSubscription<List<QuoteEntity>>? _quotesSubscription;
  Timer? _debounceTimer;

  QuoteHistoryNotifier(this._db, this._quoteRepo, this._clientRepo)
    : super(const QuoteHistoryState()) {
    _startWatching();
  }

  // ── Load / Watch ─────────────────────────────────────────────────────────────

  void _startWatching() {
    state = state.copyWith(isLoading: true);
    _quotesSubscription = _quoteRepo.watchQuotes().listen(
      (quotes) {
        // Sort DESC by createdAt
        final sorted = [...quotes]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(
          allQuotes: sorted,
          filteredQuotes: _applyFilterAndSearch(
            sorted,
            state.activeFilter,
            state.searchQuery,
          ),
          isLoading: false,
          clearError: true,
        );
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }

  @override
  void dispose() {
    _quotesSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── Filter ────────────────────────────────────────────────────────────────────

  void setFilter(QuoteHistoryFilter filter) {
    state = state.copyWith(
      activeFilter: filter,
      filteredQuotes: _applyFilterAndSearch(
        state.allQuotes,
        filter,
        state.searchQuery,
      ),
    );
  }

  // ── Search (debounced 300ms) ──────────────────────────────────────────────────

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      state = state.copyWith(
        searchQuery: query,
        filteredQuotes: _applyFilterAndSearch(
          state.allQuotes,
          state.activeFilter,
          query,
        ),
      );
    });
  }

  List<QuoteEntity> _applyFilterAndSearch(
    List<QuoteEntity> source,
    QuoteHistoryFilter filter,
    String query,
  ) {
    var result = source;

    // Apply status filter
    if (filter != QuoteHistoryFilter.all) {
      result = result.where((q) => q.status == filter.name).toList();
    }

    // Apply search
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((quote) {
        return quote.clientName.toLowerCase().contains(q) ||
            quote.jobType.toLowerCase().contains(q) ||
            quote.quoteNumber.toString().contains(q);
      }).toList();
    }

    return result;
  }

  // ── Delete Quote ──────────────────────────────────────────────────────────────

  Future<void> deleteQuote(String id) async {
    try {
      // Find the quote before deleting (for client stat update)
      final quote = state.allQuotes.firstWhere(
        (q) => q.id == id,
        orElse: () => throw Exception('Quote not found'),
      );

      // Delete from SQLite (quotes + quote_items in transaction)
      await _db.transaction(() async {
        await (_db.delete(
          _db.quoteItems,
        )..where((i) => i.quoteId.equals(id))).go();
        await (_db.delete(_db.quotes)..where((q) => q.id.equals(id))).go();
      });

      // Update client stats (decrement)
      _updateClientStats(
        quote.clientName,
        deltaQuotes: -1,
        deltaValue: -quote.totalAmount,
      );

      // Async Firestore delete
      _deleteFromFirestore(id);
    } catch (e) {
      state = state.copyWith(error: 'Delete failed: $e');
    }
  }

  void _deleteFromFirestore(String id) async {
    try {
      await FirebaseFirestore.instance.collection('quotes').doc(id).delete();
    } catch (_) {}
  }

  // ── Duplicate Quote ───────────────────────────────────────────────────────────

  Future<int?> duplicateQuote(String id) async {
    try {
      final original = state.allQuotes.firstWhere(
        (q) => q.id == id,
        orElse: () => throw Exception('Quote not found'),
      );

      const uuid = Uuid();
      final newId = uuid.v4();
      final now = DateTime.now();

      // Next quote number
      final countResult = await _db
          .customSelect('SELECT COUNT(*) as c FROM quotes')
          .getSingleOrNull();
      final newNumber = ((countResult?.data['c'] as int? ?? 0) + 1);

      // Duplicate items
      final newItems = original.items
          .map(
            (item) => QuoteItemEntity(
              id: uuid.v4(),
              quoteId: newId,
              name: item.name,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              isChecked: item.isChecked,
            ),
          )
          .toList();

      final newQuote = QuoteEntity(
        id: newId,
        quoteNumber: newNumber,
        clientId: original.clientId,
        clientName: original.clientName,
        jobType: original.jobType,
        jobAddress: original.jobAddress,
        photosPaths: original.photosPaths,
        voiceNotePath: original.voiceNotePath,
        notes: original.notes,
        laborHours: original.laborHours,
        laborRate: original.laborRate,
        taxRate: original.taxRate,
        applyTax: original.applyTax,
        status: 'pending',
        totalAmount: original.totalAmount,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
        items: newItems,
      );

      await _quoteRepo.createQuote(newQuote);
      return newNumber;
    } catch (e) {
      state = state.copyWith(error: 'Duplicate failed: $e');
      return null;
    }
  }

  // ── Update Status ─────────────────────────────────────────────────────────────

  Future<void> updateStatus(String id, String newStatus) async {
    try {
      final quote = state.allQuotes.firstWhere((q) => q.id == id);
      final oldStatus = quote.status;
      final now = DateTime.now().millisecondsSinceEpoch;

      // SQLite update
      await (_db.update(_db.quotes)..where((q) => q.id.equals(id))).write(
        QuotesCompanion(
          status: Value(newStatus),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );

      // Async Firestore update
      _updateStatusFirestore(id, newStatus, now);

      // Client stat adjustment: accepted ↔ non-accepted transitions
      final wasAccepted = oldStatus == 'accepted';
      final isAccepted = newStatus == 'accepted';
      if (wasAccepted && !isAccepted) {
        _updateClientStats(
          quote.clientName,
          deltaQuotes: 0,
          deltaValue: -quote.totalAmount,
        );
      } else if (!wasAccepted && isAccepted) {
        _updateClientStats(
          quote.clientName,
          deltaQuotes: 0,
          deltaValue: quote.totalAmount,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Status update failed: $e');
    }
  }

  void _updateStatusFirestore(String id, String status, int updatedAt) async {
    try {
      await FirebaseFirestore.instance.collection('quotes').doc(id).update({
        'status': status,
        'updatedAt': updatedAt,
        'isSynced': true,
      });
      // Mark locally as synced
      await (_db.update(_db.quotes)..where((q) => q.id.equals(id))).write(
        const QuotesCompanion(isSynced: Value(true)),
      );
    } catch (_) {}
  }

  // ── Client Stat Helper ────────────────────────────────────────────────────────

  void _updateClientStats(
    String clientName, {
    required int deltaQuotes,
    required double deltaValue,
  }) async {
    try {
      final clients = await _db.select(_db.clients).get();
      final match = clients
          .where((c) => c.name.toLowerCase() == clientName.toLowerCase())
          .firstOrNull;
      if (match == null) return;

      final newTotal = (match.totalQuotes + deltaQuotes).clamp(0, 999999);
      final newValue = (match.totalValue + deltaValue).clamp(
        0.0,
        double.infinity,
      );

      await (_db.update(
        _db.clients,
      )..where((c) => c.id.equals(match.id))).write(
        ClientsCompanion(
          totalQuotes: Value(newTotal),
          totalValue: Value(newValue),
          isSynced: const Value(false),
        ),
      );

      _clientRepo.updateClient(
        ClientEntity(
          id: match.id,
          name: match.name,
          phone: match.phone,
          email: match.email,
          address: match.address,
          totalQuotes: newTotal,
          totalValue: newValue,
          createdAt: DateTime.fromMillisecondsSinceEpoch(match.createdAt),
        ),
      );
    } catch (_) {}
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final quoteHistoryProvider =
    StateNotifierProvider<QuoteHistoryNotifier, QuoteHistoryState>((ref) {
      final db = ref.watch(databaseProvider);
      final quoteRepo = ref.watch(quoteRepositoryProvider);
      final clientRepo = ref.watch(clientRepositoryProvider);
      return QuoteHistoryNotifier(db, quoteRepo, clientRepo);
    });
