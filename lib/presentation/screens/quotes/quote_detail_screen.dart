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
import '../../../domain/entities/quote_entity.dart';
import '../../../domain/entities/user_profile_entity.dart';
import '../../providers/quote_detail_provider.dart';
import '../../providers/quote_history_provider.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kOrangeDark = Color(0xFFE85D25);
const _kMuted = Color(0xFF64748B);
const _kGreen = Color(0xFF22C55E);
const _kAmber = Color(0xFFF59E0B);
const _kRose = Color(0xFFF43F5E);
const _kBlue = Color(0xFF3B82F6);
const _kGreenWa = Color(0xFF25D366);

bool _isLegacyLaborItem(QuoteItemEntity item) {
  final name = item.name.trimLeft().toLowerCase();
  return name.startsWith('labor') && name.contains('hrs') && name.contains('/hr');
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class QuoteDetailScreen extends ConsumerWidget {
  final String quoteId;
  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(watchQuoteProvider(quoteId));

    return Scaffold(
      backgroundColor: _kBg,
      body: quoteAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kOrange)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (quote) {
          if (quote == null) {
            return const Center(
              child: Text(
                'Quote not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return _QuoteDetailBody(quote: quote);
        },
      ),
    );
  }
}

// ─── Detail Body ──────────────────────────────────────────────────────────────

class _QuoteDetailBody extends ConsumerStatefulWidget {
  final QuoteEntity quote;
  const _QuoteDetailBody({required this.quote});

  @override
  ConsumerState<_QuoteDetailBody> createState() => _QuoteDetailBodyState();
}

class _QuoteDetailBodyState extends ConsumerState<_QuoteDetailBody> {
  bool _generatingPdf = false;

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final currency = NumberFormat.currency(symbol: '\$');
    final issuedDate = DateFormat('d MMM yyyy').format(quote.createdAt);
    final validUntil = DateFormat(
      'd MMM yyyy',
    ).format(quote.createdAt.add(const Duration(days: 30)));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── App Bar ───────────────────────────────────────────────────────
          _DetailAppBar(quote: quote),

          // ── Scrollable Doc ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // PDF-style document
                  _QuoteDocumentWidget(
                    quote: quote,
                    currency: currency,
                    issuedDate: issuedDate,
                    validUntil: validUntil,
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  _DetailActionGrid(
                    quote: quote,
                    generatingPdf: _generatingPdf,
                    onGenerating: (v) => setState(() => _generatingPdf = v),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail App Bar ───────────────────────────────────────────────────────────

class _DetailAppBar extends ConsumerWidget {
  final QuoteEntity quote;
  const _DetailAppBar({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quote #${quote.quoteNumber.toString().padLeft(4, '0')}',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  quote.clientName,
                  style: GoogleFonts.publicSans(color: _kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          // Status chip
          _StatusChip(status: quote.status),
          const SizedBox(width: 8),
          // 3-dot menu
          _ThreeDotMenu(quote: quote),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    'accepted' => _kGreen,
    'rejected' => _kRose,
    _ => _kAmber,
  };

  String get _label => status.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: GoogleFonts.publicSans(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─── 3-Dot Menu ───────────────────────────────────────────────────────────────

class _ThreeDotMenu extends ConsumerWidget {
  final QuoteEntity quote;
  const _ThreeDotMenu({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      color: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _kBorder),
      ),
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
      ),
      onSelected: (value) => _onMenuSelected(context, ref, value),
      itemBuilder: (_) => [
        _menuItem('edit', Icons.edit_outlined, 'Edit Quote', Colors.white),
        _menuItem(
          'status',
          Icons.swap_horiz_rounded,
          'Change Status',
          _kOrange,
        ),
        _menuItem('duplicate', Icons.copy_outlined, 'Duplicate', _kAmber),
        _menuItem('delete', Icons.delete_outline_rounded, 'Delete', _kRose),
        _menuItem('share', Icons.share_outlined, 'Share PDF', _kBlue),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.publicSans(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenuSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'edit':
        context.push('/new-quote/step2');

      case 'status':
        if (context.mounted) {
          await showModalBottomSheet<void>(
            context: context,
            backgroundColor: _kSurface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => _StatusChangeSheet(quote: quote),
          );
        }

      case 'duplicate':
        final newNumber = await ref
            .read(quoteHistoryProvider.notifier)
            .duplicateQuote(quote.id);
        if (context.mounted && newNumber != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quote duplicated as #${newNumber.toString().padLeft(4, '0')}',
              ),
              backgroundColor: _kAmber,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

      case 'delete':
        if (context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => _DeleteDialog(quoteNumber: quote.quoteNumber),
          );
          if (confirmed == true && context.mounted) {
            await ref.read(quoteHistoryProvider.notifier).deleteQuote(quote.id);
            if (context.mounted) context.pop();
          }
        }

      case 'share':
        if (context.mounted) {
          _sharePdf(context, ref);
        }
    }
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    final profileData = await ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).userProfile)
        .getSingleOrNull();
    if (profileData == null || !context.mounted) return;

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
    final bytes = await generateQuotePdf(quote, profile);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/quote_${quote.quoteNumber}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/pdf'),
    ], subject: 'Quote #${quote.quoteNumber.toString().padLeft(4, '0')}');
  }
}

// ─── Status Change Bottom Sheet ───────────────────────────────────────────────

class _StatusChangeSheet extends ConsumerWidget {
  final QuoteEntity quote;
  const _StatusChangeSheet({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update Quote Status',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _StatusTile(
            label: 'Pending',
            description: 'Awaiting client response',
            color: _kAmber,
            icon: Icons.hourglass_empty_rounded,
            isActive: quote.status == 'pending',
            onTap: () => _select(context, ref, 'pending'),
          ),
          const SizedBox(height: 8),
          _StatusTile(
            label: 'Accepted',
            description: 'Client approved the quote',
            color: _kGreen,
            icon: Icons.check_circle_outline_rounded,
            isActive: quote.status == 'accepted',
            onTap: () => _select(context, ref, 'accepted'),
          ),
          const SizedBox(height: 8),
          _StatusTile(
            label: 'Rejected',
            description: 'Client declined the quote',
            color: _kRose,
            icon: Icons.cancel_outlined,
            isActive: quote.status == 'rejected',
            onTap: () => _select(context, ref, 'rejected'),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, String status) async {
    Navigator.of(context).pop();
    await ref
        .read(quoteHistoryProvider.notifier)
        .updateStatus(quote.id, status);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${status.toUpperCase()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          backgroundColor: _kGreen,
        ),
      );
    }
  }
}

class _StatusTile extends StatelessWidget {
  final String label, description;
  final Color color;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusTile({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.5) : _kBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.publicSans(
                      color: isActive ? color : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.publicSans(color: _kMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Delete Dialog ────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final int quoteNumber;
  const _DeleteDialog({required this.quoteNumber});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Delete Quote #${quoteNumber.toString().padLeft(4, '0')}?',
        style: GoogleFonts.publicSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'This cannot be undone.',
        style: GoogleFonts.publicSans(color: _kMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.publicSans(color: _kMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRose,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Delete',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quote Document Widget (read-only version) ────────────────────────────────

class _QuoteDocumentWidget extends ConsumerWidget {
  final QuoteEntity quote;
  final NumberFormat currency;
  final String issuedDate;
  final String validUntil;

  const _QuoteDocumentWidget({
    required this.quote,
    required this.currency,
    required this.issuedDate,
    required this.validUntil,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref
        .read(databaseProvider)
        .select(ref.read(databaseProvider).userProfile);

    final materials = quote.items
        .where((i) => i.isChecked && !_isLegacyLaborItem(i))
        .toList();
    final laborSubtotal = quote.laborHours * quote.laborRate;
    final materialSubtotal = materials.fold<double>(
      0.0,
      (s, i) => s + (i.unitPrice * i.quantity),
    );
    final subtotal = materialSubtotal + laborSubtotal;
    final taxAmount = quote.applyTax ? subtotal * (quote.taxRate / 100) : 0.0;
    final total = subtotal + taxAmount;

    return FutureBuilder(
      future: profileAsync.getSingleOrNull(),
      builder: (context, snap) {
        final profile = snap.data;
        return _DocumentCard(
          quote: quote,
          profile: profile,
          materials: materials,
          laborSubtotal: laborSubtotal,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
          currency: currency,
          issuedDate: issuedDate,
          validUntil: validUntil,
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final QuoteEntity quote;
  final dynamic profile; // UserProfileData from drift
  final List<QuoteItemEntity> materials;
  final double laborSubtotal, subtotal, taxAmount, total;
  final NumberFormat currency;
  final String issuedDate, validUntil;

  const _DocumentCard({
    required this.quote,
    required this.profile,
    required this.materials,
    required this.laborSubtotal,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.currency,
    required this.issuedDate,
    required this.validUntil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            color: _kBg,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      '#${quote.quoteNumber.toString().padLeft(4, '0')}',
                      style: GoogleFonts.publicSans(
                        color: _kOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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

          // Client strip
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
                        quote.clientName,
                        style: GoogleFonts.publicSans(
                          color: const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quote.jobAddress.isNotEmpty)
                        Text(
                          quote.jobAddress,
                          style: GoogleFonts.publicSans(
                            color: _kMuted,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
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

          // Line items table
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
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
                ...materials.map(
                  (item) => _TableItemRow(
                    name: item.name,
                    qty: item.quantity.toString(),
                    subtotal: currency.format(item.unitPrice * item.quantity),
                  ),
                ),
                _TableItemRow(
                  name:
                      'Labor — ${quote.laborHours.toStringAsFixed(1)} hrs @ ${currency.format(quote.laborRate)}/hr',
                  qty: '1',
                  subtotal: currency.format(laborSubtotal),
                  isLast: true,
                ),
              ],
            ),
          ),

          // Totals
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
                if (quote.applyTax) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label: 'Tax (${quote.taxRate.toStringAsFixed(1)}%)',
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

          // Signature
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

          // Footer
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

// ─── Table Helpers ─────────────────────────────────────────────────────────────

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
  final String name, qty, subtotal;
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

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool isBold, isLarge, isMuted;
  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isLarge = false,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final sz = isLarge ? 17.0 : 12.0;
    final c = isMuted
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
            color: c,
            fontSize: sz,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          value,
          style: GoogleFonts.publicSans(
            color: isBold ? _kOrange : c,
            fontSize: sz,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Detail Action Grid ───────────────────────────────────────────────────────

class _DetailActionGrid extends ConsumerWidget {
  final QuoteEntity quote;
  final bool generatingPdf;
  final ValueChanged<bool> onGenerating;

  const _DetailActionGrid({
    required this.quote,
    required this.generatingPdf,
    required this.onGenerating,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        _ActionBtn(
          label: 'Edit Details',
          icon: Icons.edit_outlined,
          isOutlined: true,
          onTap: () => context.push('/new-quote/step2'),
        ),
        _ActionBtn(
          label: generatingPdf ? 'Preparing...' : 'Share PDF',
          icon: Icons.picture_as_pdf_outlined,
          gradient: const LinearGradient(colors: [_kOrange, _kOrangeDark]),
          isLoading: generatingPdf,
          onTap: generatingPdf ? null : () => _onShare(context, ref),
        ),
        _ActionBtn(
          label: generatingPdf ? 'Preparing...' : 'Send WhatsApp',
          icon: Icons.chat_outlined,
          gradient: const LinearGradient(
            colors: [_kGreenWa, Color(0xFF128C7E)],
          ),
          isLoading: generatingPdf,
          onTap: generatingPdf ? null : () => _onWhatsApp(context, ref),
        ),
        _ActionBtn(
          label: generatingPdf ? 'Preparing...' : 'Email PDF',
          icon: Icons.email_outlined,
          gradient: const LinearGradient(colors: [_kBlue, Color(0xFF2563EB)]),
          isLoading: generatingPdf,
          onTap: generatingPdf ? null : () => _onEmail(context, ref),
        ),
      ],
    );
  }

  Future<UserProfileEntity?> _profile(WidgetRef ref) async {
    final d = ref.read(databaseProvider);
    final row = await d.select(d.userProfile).getSingleOrNull();
    if (row == null) return null;
    return UserProfileEntity(
      id: row.id,
      businessName: row.businessName,
      ownerName: row.ownerName,
      email: row.email,
      phone: row.phone,
      licenseNumber: row.licenseNumber,
      logoPath: row.logoPath,
      defaultHourlyRate: row.defaultHourlyRate,
      defaultTaxRate: row.defaultTaxRate,
      subscriptionPlan: row.subscriptionPlan,
      subscriptionRenewal: row.subscriptionRenewal,
    );
  }

  Future<String?> _makePdf(BuildContext context, WidgetRef ref) async {
    onGenerating(true);
    final profile = await _profile(ref);
    if (profile == null) {
      onGenerating(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your business profile first.'),
          ),
        );
      }
      return null;
    }
    final Uint8List bytes = await generateQuotePdf(quote, profile);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/quote_${quote.quoteNumber}.pdf');
    await file.writeAsBytes(bytes);
    onGenerating(false);
    return file.path;
  }

  Future<void> _onShare(BuildContext context, WidgetRef ref) async {
    final path = await _makePdf(context, ref);
    if (path == null || !context.mounted) return;
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      subject:
          'Quote #${quote.quoteNumber.toString().padLeft(4, '0')} — ${quote.clientName}',
    );
  }

  Future<void> _onWhatsApp(BuildContext context, WidgetRef ref) async {
    final path = await _makePdf(context, ref);
    if (path == null || !context.mounted) return;
    final currency = NumberFormat.currency(symbol: '\$');
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      text:
          'Hi ${quote.clientName}, please find your quote for '
          '${quote.jobType} work. '
          'Total: ${currency.format(quote.totalAmount)}.',
      subject: 'Your Quote from QuoteSnap',
    );
  }

  Future<void> _onEmail(BuildContext context, WidgetRef ref) async {
    final path = await _makePdf(context, ref);
    if (path == null || !context.mounted) return;
    final currency = NumberFormat.currency(symbol: '\$');
    final subject = Uri.encodeComponent(
      'Quote for ${quote.jobType} Work — ${quote.clientName}',
    );
    final body = Uri.encodeComponent(
      'Hi ${quote.clientName},\n\nPlease find your quote attached.\n\n'
      'Total: ${currency.format(quote.totalAmount)}\n\nBest regards',
    );
    final mailUri = Uri.parse('mailto:?subject=$subject&body=$body');
    if (await canLaunchUrl(mailUri)) await launchUrl(mailUri);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      subject: 'Quote for ${quote.jobType} Work — ${quote.clientName}',
      text: 'Hi ${quote.clientName}, please find your quote attached.',
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient? gradient;
  final bool isOutlined, isLoading;
  final VoidCallback? onTap;

  const _ActionBtn({
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
