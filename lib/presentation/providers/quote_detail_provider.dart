import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../domain/entities/quote_entity.dart';

// ─── Watch single quote ───────────────────────────────────────────────────────

final watchQuoteProvider = StreamProvider.family<QuoteEntity?, String>((
  ref,
  id,
) {
  final db = ref.watch(databaseProvider);

  return (db.select(
    db.quotes,
  )..where((q) => q.id.equals(id))).watchSingleOrNull().asyncMap((q) async {
    if (q == null) return null;

    final itemsResult = await (db.select(
      db.quoteItems,
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
  });
});

// ─── Watch quote items ────────────────────────────────────────────────────────

final watchQuoteItemsProvider =
    StreamProvider.family<List<QuoteItemEntity>, String>((ref, quoteId) {
      final db = ref.watch(databaseProvider);

      return (db.select(
        db.quoteItems,
      )..where((i) => i.quoteId.equals(quoteId))).watch().map(
        (rows) => rows
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
            .toList(),
      );
    });
