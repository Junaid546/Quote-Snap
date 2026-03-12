import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/i_quote_repository.dart';
import '../local/database.dart';
import '../remote/models/quote_firestore_model.dart';

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return QuoteRepository(db);
});

class QuoteRepository implements IQuoteRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  QuoteRepository(this._db);

  @override
  Future<List<QuoteEntity>> getQuotes() async {
    final localQuotes = await _db.select(_db.quotes).get();
    List<QuoteEntity> result = [];
    for (var q in localQuotes) {
      final itemsResult = await (_db.select(
        _db.quoteItems,
      )..where((i) => i.quoteId.equals(q.id))).get();
      final items = itemsResult
          .map(
            (i) => QuoteItemEntity(
              id: i.id,
              quoteId: i.quoteId,
              name: i.name,
              unitPrice: i.unitPrice,
              quantity: i.quantity,
              isChecked: i.isChecked,
            ),
          )
          .toList();

      result.add(
        QuoteEntity(
          id: q.id,
          quoteNumber: q.quoteNumber,
          clientId: q.clientId,
          clientName: q.clientName,
          jobType: q.jobType,
          jobAddress: q.jobAddress,
          photosPaths: List<String>.from(jsonDecode(q.photosPaths)),
          voiceNotePath: q.voiceNotePath,
          notes: q.notes,
          laborHours: q.laborHours,
          laborRate: q.laborRate,
          taxRate: q.taxRate,
          applyTax: q.applyTax,
          status: q.status,
          totalAmount: q.totalAmount,
          createdAt: DateTime.fromMillisecondsSinceEpoch(q.createdAt),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(q.updatedAt),
          isSynced: q.isSynced,
          items: items,
        ),
      );
    }
    return result;
  }

  @override
  Stream<List<QuoteEntity>> watchQuotes() {
    return _db.select(_db.quotes).watch().asyncMap((localQuotes) async {
      List<QuoteEntity> result = [];
      for (var q in localQuotes) {
        final itemsResult = await (_db.select(
          _db.quoteItems,
        )..where((i) => i.quoteId.equals(q.id))).get();
        final items = itemsResult
            .map(
              (i) => QuoteItemEntity(
                id: i.id,
                quoteId: i.quoteId,
                name: i.name,
                unitPrice: i.unitPrice,
                quantity: i.quantity,
                isChecked: i.isChecked,
              ),
            )
            .toList();

        result.add(
          QuoteEntity(
            id: q.id,
            quoteNumber: q.quoteNumber,
            clientId: q.clientId,
            clientName: q.clientName,
            jobType: q.jobType,
            jobAddress: q.jobAddress,
            photosPaths: List<String>.from(jsonDecode(q.photosPaths)),
            voiceNotePath: q.voiceNotePath,
            notes: q.notes,
            laborHours: q.laborHours,
            laborRate: q.laborRate,
            taxRate: q.taxRate,
            applyTax: q.applyTax,
            status: q.status,
            totalAmount: q.totalAmount,
            createdAt: DateTime.fromMillisecondsSinceEpoch(q.createdAt),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(q.updatedAt),
            isSynced: q.isSynced,
            items: items,
          ),
        );
      }
      return result;
    });
  }

  @override
  Future<QuoteEntity?> getQuoteById(String id) async {
    final q = await (_db.select(
      _db.quotes,
    )..where((q) => q.id.equals(id))).getSingleOrNull();
    if (q == null) return null;

    final itemsResult = await (_db.select(
      _db.quoteItems,
    )..where((i) => i.quoteId.equals(q.id))).get();
    final items = itemsResult
        .map(
          (i) => QuoteItemEntity(
            id: i.id,
            quoteId: i.quoteId,
            name: i.name,
            unitPrice: i.unitPrice,
            quantity: i.quantity,
            isChecked: i.isChecked,
          ),
        )
        .toList();

    return QuoteEntity(
      id: q.id,
      quoteNumber: q.quoteNumber,
      clientId: q.clientId,
      clientName: q.clientName,
      jobType: q.jobType,
      jobAddress: q.jobAddress,
      photosPaths: List<String>.from(jsonDecode(q.photosPaths)),
      voiceNotePath: q.voiceNotePath,
      notes: q.notes,
      laborHours: q.laborHours,
      laborRate: q.laborRate,
      taxRate: q.taxRate,
      applyTax: q.applyTax,
      status: q.status,
      totalAmount: q.totalAmount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(q.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(q.updatedAt),
      isSynced: q.isSynced,
      items: items,
    );
  }

  @override
  Future<void> createQuote(QuoteEntity quote) async {
    await _db.transaction(() async {
      await _db
          .into(_db.quotes)
          .insert(
            QuotesCompanion.insert(
              id: quote.id,
              quoteNumber: quote.quoteNumber,
              clientId: quote.clientId,
              clientName: quote.clientName,
              jobType: quote.jobType,
              jobAddress: quote.jobAddress,
              photosPaths: jsonEncode(quote.photosPaths),
              voiceNotePath: Value(quote.voiceNotePath),
              notes: quote.notes,
              laborHours: quote.laborHours,
              laborRate: quote.laborRate,
              taxRate: quote.taxRate,
              applyTax: quote.applyTax,
              status: Value(quote.status),
              totalAmount: quote.totalAmount,
              createdAt: quote.createdAt.millisecondsSinceEpoch,
              updatedAt: quote.updatedAt.millisecondsSinceEpoch,
              isSynced: const Value(false),
            ),
          );

      for (var item in quote.items) {
        await _db
            .into(_db.quoteItems)
            .insert(
              QuoteItemsCompanion.insert(
                id: item.id,
                quoteId: item.quoteId,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                isChecked: item.isChecked,
              ),
            );
      }
    });

    _syncToFirestore(quote);
  }

  @override
  Future<void> updateQuote(QuoteEntity quote) async {
    await _db.transaction(() async {
      await (_db.update(_db.quotes)..where((q) => q.id.equals(quote.id))).write(
        QuotesCompanion(
          clientId: Value(quote.clientId),
          clientName: Value(quote.clientName),
          jobType: Value(quote.jobType),
          jobAddress: Value(quote.jobAddress),
          photosPaths: Value(jsonEncode(quote.photosPaths)),
          voiceNotePath: Value(quote.voiceNotePath),
          notes: Value(quote.notes),
          laborHours: Value(quote.laborHours),
          laborRate: Value(quote.laborRate),
          taxRate: Value(quote.taxRate),
          applyTax: Value(quote.applyTax),
          status: Value(quote.status),
          totalAmount: Value(quote.totalAmount),
          updatedAt: Value(quote.updatedAt.millisecondsSinceEpoch),
          isSynced: const Value(false),
        ),
      );

      await (_db.delete(
        _db.quoteItems,
      )..where((i) => i.quoteId.equals(quote.id))).go();
      for (var item in quote.items) {
        await _db
            .into(_db.quoteItems)
            .insert(
              QuoteItemsCompanion.insert(
                id: item.id,
                quoteId: item.quoteId,
                name: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                isChecked: item.isChecked,
              ),
            );
      }
    });

    _syncToFirestore(quote);
  }

  @override
  Future<void> deleteQuote(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.quoteItems,
      )..where((i) => i.quoteId.equals(id))).go();
      await (_db.delete(_db.quotes)..where((q) => q.id.equals(id))).go();
    });

    try {
      await _firestore.collection('quotes').doc(id).delete();
    } catch (_) {}
  }

  @override
  Future<void> syncUnsyncedQuotes() async {
    final unsynced = await (_db.select(
      _db.quotes,
    )..where((q) => q.isSynced.equals(false))).get();
    for (var q in unsynced) {
      final entity = await getQuoteById(q.id);
      if (entity != null) _syncToFirestore(entity);
    }
  }

  void _syncToFirestore(QuoteEntity quote) async {
    try {
      final model = QuoteFirestoreModel.fromEntity(quote);
      await _firestore.collection('quotes').doc(quote.id).set(model.toJson());

      await (_db.update(_db.quotes)..where((q) => q.id.equals(quote.id))).write(
        const QuotesCompanion(isSynced: Value(true)),
      );
    } catch (e) {
      await (_db.update(_db.quotes)..where((q) => q.id.equals(quote.id))).write(
        const QuotesCompanion(isSynced: Value(false)),
      );
    }
  }
}
