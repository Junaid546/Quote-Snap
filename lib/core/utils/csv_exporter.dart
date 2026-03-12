import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/quote_entity.dart';

/// Utility class for exporting QuoteEntity data to a well-formatted CSV file.
class CsvExporter {
  static const _headers = [
    'Quote #',
    'Client Name',
    'Job Type',
    'Address',
    'Status',
    'Total Amount',
    'Tax Applied',
    'Labor Hours',
    'Labor Rate',
    'Materials Total',
    'Created Date',
    'Notes',
  ];

  /// Exports a list of quotes to a CSV file and returns the [File].
  /// Caller is expected to use `share_plus` to share the file.
  static Future<File> exportQuotesToCsv(List<QuoteEntity> quotes) async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final rows = <List<String>>[_headers];

    for (final q in quotes) {
      final createdDate = dateFmt.format(q.createdAt);

      // Compute materials total from items
      final materialTotal = q.items
          .where((item) => item.isChecked)
          .fold<double>(
            0.0,
            (sum, item) => sum + (item.unitPrice * item.quantity),
          );

      rows.add([
        q.quoteNumber.toString(),
        _escape(q.clientName),
        _escape(q.jobType),
        _escape(q.jobAddress),
        q.status,
        q.totalAmount.toStringAsFixed(2),
        q.applyTax ? 'Yes' : 'No',
        q.laborHours.toStringAsFixed(1),
        q.laborRate.toStringAsFixed(2),
        materialTotal.toStringAsFixed(2),
        createdDate,
        _escape(q.notes),
      ]);
    }

    final csvContent = rows
        .map(
          (row) =>
              row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','),
        )
        .join('\n');

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/quotesnap_export_$timestamp.csv');
    await file.writeAsString(csvContent);

    debugPrint(
      '[CsvExporter] Exported ${quotes.length} quotes to ${file.path}',
    );
    return file;
  }

  static String _escape(String value) => value.trim();
}
