// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/pdf_generator.dart';
import '../../../data/local/database.dart';
import '../../../domain/entities/user_profile_entity.dart';
import '../../providers/dashboard_provider.dart';
import '../../../domain/entities/quote_entity.dart';
import '../../providers/new_quote_provider.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFFF6B35);
const _kOrangeDark = Color(0xFFE85D25);
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFF334155);
const _kGreen = Color(0xFF22C55E);
const _kGreenWa = Color(0xFF25D366);
const _kBlue = Color(0xFF3B82F6);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class NewQuoteStep3Screen extends ConsumerWidget {
  const NewQuoteStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteState = ref.watch(newQuoteProvider);
    final currency = NumberFormat.currency(symbol: '\$');
    final issuedDate = DateFormat('d MMM yyyy').format(DateTime.now());
    final validUntil = DateFormat(
      'd MMM yyyy',
    ).format(DateTime.now().add(const Duration(days: 30)));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──────────────────────────────────────────────────────
            _TopBar(),
            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Document preview
                    _QuoteDocumentWidget(
                      quoteState: quoteState,
                      currency: currency,
                      issuedDate: issuedDate,
                      validUntil: validUntil,
                    ),
                    const SizedBox(height: 24),
                    // "Looks good?"
                    Text(
                      'Looks good?',
                      style: GoogleFonts.publicSans(
                        color: _kMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons 2×2 grid
                    _ActionGrid(quoteState: quoteState),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 3 of 3',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'REVIEW QUOTE',
                  style: GoogleFonts.publicSans(
                    color: _kMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Step pips
          Row(
            children: List.generate(3, (i) {
              final isActive = i == 2;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 6),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? _kOrange : _kBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Quote Document Widget ────────────────────────────────────────────────────

class _QuoteDocumentWidget extends ConsumerWidget {
  final NewQuoteState quoteState;
  final NumberFormat currency;
  final String issuedDate;
  final String validUntil;

  const _QuoteDocumentWidget({
    required this.quoteState,
    required this.currency,
    required this.issuedDate,
    required this.validUntil,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    const fakeQuoteNumber = 1; // Placeholder until saved

    // Checked material items
    final materials = quoteState.items.where((i) => i.isChecked).toList();
    final laborSubtotal = quoteState.laborSubtotal;
    final materialSubtotal = quoteState.materialSubtotal;
    final subtotal = materialSubtotal + laborSubtotal;
    final taxAmount = quoteState.taxAmount;
    final total = quoteState.estimatedTotal;

    final profile = profileAsync.whenOrNull(data: (d) => d);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Document Header ───────────────────────────────────────────────
          Container(
            color: _kBg,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: logo + business name
                Expanded(
                  child: Row(
                    children: [
                      _LogoWidget(logoPath: profile?.logoPath),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (profile?.businessName ?? 'YOUR BUSINESS')
                                .toUpperCase(),
                            style: GoogleFonts.publicSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'CONTRACTOR',
                            style: GoogleFonts.publicSans(
                              color: _kMuted,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: QUOTE title + number + dates
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'QUOTE',
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '#${fakeQuoteNumber.toString().padLeft(4, '0')}',
                      style: GoogleFonts.publicSans(
                        color: _kOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Issued: $issuedDate',
                      style: GoogleFonts.publicSans(
                        color: _kMuted,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      'Valid until: $validUntil',
                      style: GoogleFonts.publicSans(
                        color: _kMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Client Strip ──────────────────────────────────────────────────
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREPARED FOR',
                        style: GoogleFonts.publicSans(
                          color: _kMuted,
                          fontSize: 8,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quoteState.clientName.isEmpty
                            ? 'Client Name'
                            : quoteState.clientName,
                        style: GoogleFonts.publicSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quoteState.jobAddress.isNotEmpty)
                        Text(
                          quoteState.jobAddress,
                          style: GoogleFonts.publicSans(
                            color: _kMuted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                // Verified badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Line Items Table ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Table header
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                  child: const _TableHeaderRow(),
                ),
                // Material rows
                ...materials.map(
                  (item) => _TableItemRow(
                    name: item.name,
                    qty: item.quantity.toString(),
                    subtotal: currency.format(item.lineTotal),
                  ),
                ),
                // Labor row
                _TableItemRow(
                  name:
                      'Labor — ${quoteState.laborHours.toStringAsFixed(1)} hrs @ ${currency.format(quoteState.laborRate)}/hr',
                  qty: '1',
                  subtotal: currency.format(laborSubtotal),
                  isLast: true,
                ),
              ],
            ),
          ),

          // ── Totals ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: currency.format(subtotal),
                  isMuted: true,
                ),
                if (quoteState.applyTax) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label: 'Tax (${quoteState.taxRate.toStringAsFixed(1)}%)',
                    value: currency.format(taxAmount),
                    isMuted: true,
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(color: Color(0xFF0F172A), thickness: 2),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'FINAL TOTAL',
                  value: currency.format(total),
                  isBold: true,
                  isLarge: true,
                ),
              ],
            ),
          ),

          // ── Signature Line ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '~ Authorized',
                  style: GoogleFonts.dancingScript(
                    color: const Color(0xFF475569),
                    fontSize: 18,
                  ),
                ),
                Container(
                  height: 1,
                  width: 140,
                  color: const Color(0xFFCBD5E1),
                  margin: const EdgeInsets.only(top: 2),
                ),
                const SizedBox(height: 2),
                Text(
                  'Authorized Signature',
                  style: GoogleFonts.publicSans(color: _kMuted, fontSize: 8),
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  profile?.businessName ?? '',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
                Text(
                  'Generated by QuoteSnap',
                  style: GoogleFonts.publicSans(color: _kMuted, fontSize: 9),
                ),
                Text(
                  profile?.phone ?? '',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Widget ──────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  final String? logoPath;
  const _LogoWidget({this.logoPath});

  @override
  Widget build(BuildContext context) {
    if (logoPath != null && logoPath!.isNotEmpty) {
      final file = File(logoPath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, width: 40, height: 40, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kOrange, _kOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.construction, color: Colors.white, size: 20),
    );
  }
}

// ─── Table Widgets ─────────────────────────────────────────────────────────────

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'SERVICE DESCRIPTION',
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              'QTY',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'SUBTOTAL',
              textAlign: TextAlign.right,
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableItemRow extends StatelessWidget {
  final String name;
  final String qty;
  final String subtotal;
  final bool isLast;

  const _TableItemRow({
    required this.name,
    required this.qty,
    required this.subtotal,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              name,
              style: GoogleFonts.publicSans(
                color: const Color(0xFF1E293B),
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                color: const Color(0xFF475569),
                fontSize: 10,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              subtotal,
              textAlign: TextAlign.right,
              style: GoogleFonts.publicSans(
                color: const Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Total Row ────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isLarge;
  final bool isMuted;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isLarge = false,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isLarge ? 17.0 : 12.0;
    final textColor = isMuted
        ? _kMuted
        : isBold
        ? const Color(0xFF0F172A)
        : const Color(0xFF1E293B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.publicSans(
            color: textColor,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          value,
          style: GoogleFonts.publicSans(
            color: isBold ? _kOrange : textColor,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Action 2×2 Grid ──────────────────────────────────────────────────────────

class _ActionGrid extends ConsumerStatefulWidget {
  final NewQuoteState quoteState;
  const _ActionGrid({required this.quoteState});

  @override
  ConsumerState<_ActionGrid> createState() => _ActionGridState();
}

class _ActionGridState extends ConsumerState<_ActionGrid> {
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    final isSaving = widget.quoteState.isSaving;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        // 1. Edit Details
        _ActionButton(
          label: 'Edit Details',
          icon: Icons.edit_outlined,
          isOutlined: true,
          onTap: () => context.go('/new-quote/step2'),
        ),
        // 2. Finalize & Save
        _ActionButton(
          label: isSaving ? 'Saving...' : 'Finalize & Save',
          icon: Icons.save_outlined,
          gradient: const LinearGradient(
            colors: [_kOrange, _kOrangeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isLoading: isSaving,
          onTap: isSaving ? null : () => _onSave(context),
        ),
        // 3. Send WhatsApp
        _ActionButton(
          label: _generatingPdf ? 'Preparing...' : 'Send WhatsApp',
          icon: Icons.chat_outlined,
          gradient: const LinearGradient(
            colors: [_kGreenWa, Color(0xFF128C7E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isLoading: _generatingPdf,
          onTap: _generatingPdf ? null : () => _onWhatsApp(context),
        ),
        // 4. Email PDF
        _ActionButton(
          label: _generatingPdf ? 'Preparing...' : 'Email PDF',
          icon: Icons.email_outlined,
          gradient: const LinearGradient(
            colors: [_kBlue, Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          isLoading: _generatingPdf,
          onTap: _generatingPdf ? null : () => _onEmail(context),
        ),
      ],
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _onSave(BuildContext context) async {
    final notifier = ref.read(newQuoteProvider.notifier);
    final quoteNumber = await notifier.saveQuote(context);

    if (!mounted) return;

    if (quoteNumber != null && quoteNumber > 0) {
      // Reset state and navigate home
      notifier.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quote #${quoteNumber.toString().padLeft(4, '0')} saved!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.go('/home/quotes');
    } else if (quoteNumber == null) {
      // Generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.quoteState.saveError ??
                'Failed to save quote. Please try again.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    // quoteNumber == -1 means blocked by free tier dialog (already shown)
  }

  Future<String?> _buildAndSavePdf(BuildContext context) async {
    final profileData = await ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).userProfile)
        .getSingleOrNull();

    if (profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your business profile first.'),
        ),
      );
      return null;
    }

    final profile = UserProfileEntity(
      id: profileData.id,
      businessName: profileData.businessName,
      ownerName: profileData.ownerName,
      email: profileData.email,
      phone: profileData.phone,
      licenseNumber: profileData.licenseNumber,
      logoPath: profileData.logoPath,
      defaultHourlyRate: profileData.defaultHourlyRate,
      defaultTaxRate: profileData.defaultTaxRate,
      subscriptionPlan: profileData.subscriptionPlan,
      subscriptionRenewal: profileData.subscriptionRenewal,
    );

    final s = widget.quoteState;
    final now = DateTime.now();
    final checkedItems = s.items.where((i) => i.isChecked).toList();

    final quoteEntity = QuoteEntity(
      id: 'preview',
      quoteNumber: 0,
      clientId: '',
      clientName: s.clientName,
      jobType: s.selectedJobType ?? 'General',
      jobAddress: s.jobAddress,
      photosPaths: const [],
      notes: s.notes,
      laborHours: s.laborHours,
      laborRate: s.laborRate,
      taxRate: s.taxRate,
      applyTax: s.applyTax,
      status: 'pending',
      totalAmount: s.estimatedTotal,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      items: checkedItems
          .map(
            (item) => QuoteItemEntity(
              id: '',
              quoteId: 'preview',
              name: item.name,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              isChecked: true,
            ),
          )
          .toList(),
    );

    final Uint8List pdfBytes = await generateQuotePdf(quoteEntity, profile);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/quote_preview.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  Future<void> _onWhatsApp(BuildContext context) async {
    setState(() => _generatingPdf = true);
    try {
      final pdfPath = await _buildAndSavePdf(context);
      if (pdfPath == null || !mounted) return;

      final s = widget.quoteState;
      final currency = NumberFormat.currency(symbol: '\$');

      await Share.shareXFiles(
        [XFile(pdfPath, mimeType: 'application/pdf')],
        text:
            'Hi ${s.clientName}, please find your quote for '
            '${s.selectedJobType ?? 'general'} work. '
            'Total: ${currency.format(s.estimatedTotal)}.',
        subject: 'Your Quote from QuoteSnap',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _onEmail(BuildContext context) async {
    setState(() => _generatingPdf = true);
    try {
      final pdfPath = await _buildAndSavePdf(context);
      if (pdfPath == null || !mounted) return;

      final s = widget.quoteState;
      final currency = NumberFormat.currency(symbol: '\$');
      final subject = Uri.encodeComponent(
        'Quote for ${s.selectedJobType ?? 'General'} Work — ${s.clientName}',
      );
      final body = Uri.encodeComponent(
        'Hi ${s.clientName},\n\n'
        'Please find your quote attached.\n\n'
        'Job Type: ${s.selectedJobType ?? 'General'}\n'
        'Total: ${currency.format(s.estimatedTotal)}\n\n'
        'Don\'t hesitate to reach out with any questions.\n\n'
        'Best regards',
      );

      // Try mailto first
      final mailUri = Uri.parse('mailto:?subject=$subject&body=$body');
      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
      }

      // Also trigger native share with the PDF
      await Share.shareXFiles(
        [XFile(pdfPath, mimeType: 'application/pdf')],
        subject:
            'Quote for ${s.selectedJobType ?? 'General'} Work — ${s.clientName}',
        text: 'Hi ${s.clientName}, please find your quote attached.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient? gradient;
  final bool isOutlined;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.gradient,
    this.isOutlined = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: isOutlined ? null : gradient,
          color: isOutlined ? _kSurface : null,
          borderRadius: BorderRadius.circular(14),
          border: isOutlined ? Border.all(color: _kBorder, width: 1.5) : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: (gradient?.colors.first ?? _kOrange).withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
