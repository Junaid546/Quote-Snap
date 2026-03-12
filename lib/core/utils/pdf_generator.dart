import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/quote_entity.dart';
import '../../domain/entities/user_profile_entity.dart';

bool _isLegacyLaborItem(QuoteItemEntity item) {
  final name = item.name.trimLeft().toLowerCase();
  return name.startsWith('labor') && name.contains('hrs') && name.contains('/hr');
}

// ─── Colour constants matching design ──────────────────────────────────────────
const _kOrange = PdfColor.fromInt(0xFFFF6B35);
const _kDarkBg = PdfColor.fromInt(0xFF0F172A);
const _kGrey = PdfColor.fromInt(0xFFF1F5F9);
const _kMuted = PdfColor.fromInt(0xFF64748B);
const _kGreen = PdfColor.fromInt(0xFF22C55E);
const _kWhite = PdfColors.white;
const _kBlack = PdfColors.black;

/// Generates a professional PDF for a quote.
///
/// Returns the raw bytes (Uint8List) which can be saved to a file or shared.
Future<Uint8List> generateQuotePdf(
  QuoteEntity quote,
  UserProfileEntity profile,
) async {
  final pdf = pw.Document();
  final currency = NumberFormat.currency(symbol: '\$');
  final dateFmt = DateFormat('dd MMM yyyy');

  final issuedDate = dateFmt.format(quote.createdAt);
  final validUntil = dateFmt.format(
    quote.createdAt.add(const Duration(days: 30)),
  );

  // Load logo if present
  pw.MemoryImage? logoImage;
  if (profile.logoPath != null && profile.logoPath!.isNotEmpty) {
    final file = File(profile.logoPath!);
    if (await file.exists()) {
      logoImage = pw.MemoryImage(await file.readAsBytes());
    }
  }

  // Checked material items
  final materialItems = quote.items
      .where((i) => i.isChecked && !_isLegacyLaborItem(i))
      .toList();
  final laborSubtotal = quote.laborHours * quote.laborRate;
  final materialSubtotal = materialItems.fold<double>(
    0.0,
    (sum, i) => sum + (i.unitPrice * i.quantity),
  );
  final subtotal = materialSubtotal + laborSubtotal;
  final taxAmount = quote.applyTax ? subtotal * (quote.taxRate / 100) : 0.0;
  final total = subtotal + taxAmount;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            pw.Container(
              color: _kDarkBg,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Left: logo + business name
                  pw.Row(
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 48,
                          height: 48,
                          decoration: const pw.BoxDecoration(
                            color: _kWhite,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.ClipOval(
                            child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                      ] else ...[
                        pw.Container(
                          width: 48,
                          height: 48,
                          decoration: const pw.BoxDecoration(
                            color: _kOrange,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              profile.businessName.isNotEmpty
                                  ? profile.businessName[0].toUpperCase()
                                  : 'B',
                              style: pw.TextStyle(
                                color: _kWhite,
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            profile.businessName.toUpperCase(),
                            style: pw.TextStyle(
                              color: _kWhite,
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'CONTRACTOR',
                            style: const pw.TextStyle(
                              color: _kMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Right: QUOTE title + number + dates
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'QUOTE',
                        style: pw.TextStyle(
                          color: _kWhite,
                          fontSize: 28,
                          fontStyle: pw.FontStyle.italic,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '#${quote.quoteNumber.toString().padLeft(4, '0')}',
                        style: const pw.TextStyle(
                          color: _kOrange,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Issued: $issuedDate',
                        style: const pw.TextStyle(color: _kMuted, fontSize: 10),
                      ),
                      pw.Text(
                        'Valid until: $validUntil',
                        style: const pw.TextStyle(color: _kMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── CLIENT STRIP ─────────────────────────────────────────────────
            pw.Container(
              color: _kGrey,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PREPARED FOR',
                        style: const pw.TextStyle(color: _kMuted, fontSize: 9),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        quote.clientName,
                        style: pw.TextStyle(
                          color: _kBlack,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (quote.jobAddress.isNotEmpty)
                        pw.Text(
                          quote.jobAddress,
                          style: const pw.TextStyle(
                            color: _kMuted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  // Verified badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _kGreen,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      '✓  VERIFIED QUOTE',
                      style: pw.TextStyle(
                        color: _kWhite,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ── JOB TYPE ────────────────────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 32),
              child: pw.Text(
                'Job Type: ${quote.jobType}',
                style: pw.TextStyle(
                  color: _kBlack,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // ── LINE ITEMS TABLE ─────────────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 32),
              child: pw.Table(
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: _kGrey, width: 1),
                  horizontalInside: pw.BorderSide(color: _kGrey, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FixedColumnWidth(50),
                  2: const pw.FixedColumnWidth(80),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _kDarkBg),
                    children: [
                      _tableHeader('SERVICE DESCRIPTION'),
                      _tableHeader('QTY', align: pw.TextAlign.center),
                      _tableHeader('SUBTOTAL', align: pw.TextAlign.right),
                    ],
                  ),
                  // Material rows
                  ...materialItems.map(
                    (item) => pw.TableRow(
                      children: [
                        _tableCell(item.name),
                        _tableCell(
                          item.quantity.toString(),
                          align: pw.TextAlign.center,
                        ),
                        _tableCell(
                          currency.format(item.unitPrice * item.quantity),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                  // Labor row
                  pw.TableRow(
                    children: [
                      _tableCell(
                        'Labor — ${quote.laborHours.toStringAsFixed(1)} hrs @ ${currency.format(quote.laborRate)}/hr',
                      ),
                      _tableCell('1', align: pw.TextAlign.center),
                      _tableCell(
                        currency.format(laborSubtotal),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // ── TOTALS ───────────────────────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 32),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _totalRow(
                        'Subtotal',
                        currency.format(subtotal),
                        isMuted: true,
                      ),
                      if (quote.applyTax) ...[
                        pw.SizedBox(height: 4),
                        _totalRow(
                          'Tax (${quote.taxRate.toStringAsFixed(1)}%)',
                          currency.format(taxAmount),
                          isMuted: true,
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      pw.Container(height: 2, width: 220, color: _kDarkBg),
                      pw.SizedBox(height: 6),
                      _totalRow(
                        'TOTAL',
                        currency.format(total),
                        isBold: true,
                        isLarge: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ── NOTES ────────────────────────────────────────────────────────
            if (quote.notes.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Notes:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: _kMuted,
                      ),
                    ),
                    pw.Text(
                      quote.notes,
                      style: const pw.TextStyle(fontSize: 10, color: _kMuted),
                    ),
                  ],
                ),
              ),

            // ── SIGNATURE ────────────────────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(32, 16, 32, 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(height: 1, width: 160, color: _kMuted),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Authorized Signature',
                    style: const pw.TextStyle(color: _kMuted, fontSize: 9),
                  ),
                ],
              ),
            ),

            // ── FOOTER ───────────────────────────────────────────────────────
            pw.Container(
              color: _kDarkBg,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    profile.businessName,
                    style: const pw.TextStyle(color: _kWhite, fontSize: 10),
                  ),
                  pw.Text(
                    'Generated by QuoteSnap',
                    style: const pw.TextStyle(color: _kMuted, fontSize: 9),
                  ),
                  pw.Text(
                    profile.phone,
                    style: const pw.TextStyle(color: _kWhite, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

pw.Widget _tableHeader(String text, {pw.TextAlign? align}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: pw.Text(
      text,
      textAlign: align ?? pw.TextAlign.left,
      style: pw.TextStyle(
        color: _kWhite,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _tableCell(String text, {pw.TextAlign? align}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: pw.Text(
      text,
      textAlign: align ?? pw.TextAlign.left,
      style: const pw.TextStyle(color: _kBlack, fontSize: 10),
    ),
  );
}

pw.Widget _totalRow(
  String label,
  String value, {
  bool isBold = false,
  bool isLarge = false,
  bool isMuted = false,
}) {
  final fontSize = isLarge ? 16.0 : 11.0;
  final color = isMuted ? _kMuted : _kBlack;
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.SizedBox(width: 140),
      pw.Text(
        label,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : null,
          fontSize: fontSize,
          color: color,
        ),
      ),
      pw.SizedBox(width: 24),
      pw.SizedBox(
        width: 80,
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : null,
            fontSize: fontSize,
            color: isBold ? _kOrange : color,
          ),
        ),
      ),
    ],
  );
}
