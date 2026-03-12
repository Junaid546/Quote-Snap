import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/client_entity.dart';
import '../../../domain/entities/quote_entity.dart';
import '../../providers/client_provider.dart';
import '../../providers/quote_history_provider.dart';
import '../../widgets/clients/add_edit_client_sheet.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);
const _kGreenWa = Color(0xFF25D366);
const _kRose = Color(0xFFF43F5E);

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  QuoteHistoryFilter _activeFilter = QuoteHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(watchClientProvider(widget.clientId));
    final quotesAsync = ref.watch(quoteHistoryProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          clientAsync.whenData((client) {
                if (client == null) return const SizedBox();
                return _MenuButton(client: client);
              }).value ??
              const SizedBox(),
        ],
      ),
      body: clientAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kOrange)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (client) {
          if (client == null) {
            return const Center(
              child: Text(
                'Client not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final clientQuotes = quotesAsync.allQuotes
              .where((q) => q.clientId == client.id)
              .toList();

          final filteredQuotes = _activeFilter == QuoteHistoryFilter.all
              ? clientQuotes
              : clientQuotes
                    .where((q) => q.status == _activeFilter.name)
                    .toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── Profile Section ──
                      _ProfileHeader(client: client),
                      const SizedBox(height: 24),

                      // ── Stats Cards ──
                      _StatsRow(client: client, quotes: clientQuotes),
                      const SizedBox(height: 24),

                      // ── Quick Actions ──
                      _QuickActions(client: client),
                      const SizedBox(height: 32),

                      // ── Quote History ──
                      _QuoteHistorySection(
                        quotes: filteredQuotes,
                        totalCount: clientQuotes.length,
                        activeFilter: _activeFilter,
                        onFilterChanged: (f) =>
                            setState(() => _activeFilter = f),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons
              _BottomActions(client: client),
            ],
          );
        },
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ClientEntity client;
  const _ProfileHeader({required this.client});

  @override
  Widget build(BuildContext context) {
    final initials = client.name.length >= 2
        ? client.name.substring(0, 2).toUpperCase()
        : client.name.toUpperCase();

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kAmber, Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kAmber.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          client.name,
          style: GoogleFonts.publicSans(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kOrange.withValues(alpha: 0.5)),
          ),
          child: Text(
            'Client'.toUpperCase(),
            style: GoogleFonts.publicSans(
              color: _kOrange,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ContactRow(
          icon: Icons.phone_outlined,
          label: client.phone ?? 'No phone',
          isTappable: client.phone != null,
        ),
        const SizedBox(height: 8),
        _ContactRow(
          icon: Icons.email_outlined,
          label: client.email ?? 'No email',
          isTappable: client.email != null,
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isTappable;
  const _ContactRow({
    required this.icon,
    required this.label,
    this.isTappable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isTappable ? () => _launch(context, label) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _kMuted, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.publicSans(
              color: isTappable ? Colors.white70 : _kMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _launch(BuildContext context, String value) async {
    final uri = value.contains('@')
        ? Uri.parse('mailto:$value')
        : Uri.parse('tel:$value');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No compatible app found.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// ─── Stats Cards ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ClientEntity client;
  final List<QuoteEntity> quotes;
  const _StatsRow({required this.client, required this.quotes});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');
    final acceptedCount = quotes.where((q) => q.status == 'accepted').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Quotes',
            value: '${client.totalQuotes}',
            color: _kAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Accepted',
            value: '$acceptedCount',
            color: _kGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: _StatCard(
            label: 'Total Value',
            value: currency.format(client.totalValue),
            color: Colors.white,
            isCurrency: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isCurrency;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: isCurrency
                ? GoogleFonts.jetBrainsMono(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  )
                : GoogleFonts.publicSans(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              color: _kMuted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  final ClientEntity client;
  const _QuickActions({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        _ActionIcon(
          icon: Icons.phone_rounded,
          color: _kAmber,
          onTap: () => _call(context, client.phone),
        ),
        _ActionIcon(
          icon: Icons.sms_rounded,
          color: _kGreen,
          onTap: () => _sms(context, client.phone),
        ),
        _ActionIcon(
          icon: Icons.chat_bubble_outline_rounded,
          color: _kGreenWa,
          onTap: () => _wa(context, client.phone),
        ),
        _ActionIcon(
          icon: Icons.email_rounded,
          color: Colors.blueAccent,
          onTap: () => _mail(context, client.email),
        ),
        _ActionIcon(
          icon: Icons.edit_rounded,
          color: Colors.white70,
          onTap: () => _edit(context),
        ),
        _ActionIcon(
          icon: Icons.delete_outline_rounded,
          color: _kRose,
          onTap: () => _delete(context, ref),
        ),
      ],
    );
  }

  void _call(BuildContext context, String? p) async {
    if (p == null) return;
    final uri = Uri.parse('tel:$p');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'No dialer app available.');
    }
  }

  void _sms(BuildContext context, String? p) async {
    if (p == null) return;
    final uri = Uri.parse('sms:$p');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'No messaging app available.');
    }
  }

  void _wa(BuildContext context, String? p) async {
    if (p == null) return;
    final uri = Uri.parse(
      'https://wa.me/${p.replaceAll(RegExp(r'\D'), '')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'WhatsApp is not available.');
    }
  }

  void _mail(BuildContext context, String? e) async {
    if (e == null) return;
    final uri = Uri.parse('mailto:$e');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError(context, 'No email app available.');
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditClientSheet(client: client),
    );
  }

  void _delete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(clientProvider.notifier);
    final count = await notifier.getClientQuoteCount(client.id);

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSurface,
        title: Text(
          'Delete Client?',
          style: GoogleFonts.publicSans(color: Colors.white),
        ),
        content: Text(
          count > 0
              ? 'This client has $count quotes. Deleting will NOT delete their quotes. Continue?'
              : 'Are you sure you want to delete this client?',
          style: GoogleFonts.publicSans(color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteClient(client.id);
      if (context.mounted) {
        context.go('/home/clients');
      }
    }
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Quote History Section ────────────────────────────────────────────────────

class _QuoteHistorySection extends StatelessWidget {
  final List<QuoteEntity> quotes;
  final int totalCount;
  final QuoteHistoryFilter activeFilter;
  final ValueChanged<QuoteHistoryFilter> onFilterChanged;

  const _QuoteHistorySection({
    required this.quotes,
    required this.totalCount,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quote History',
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalCount',
                style: GoogleFonts.jetBrainsMono(
                  color: _kOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FilterTabs(active: activeFilter, onChanged: onFilterChanged),
        const SizedBox(height: 16),
        if (quotes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No matching quotes found.',
                style: GoogleFonts.publicSans(color: _kMuted),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: quotes.length,
            itemBuilder: (context, index) =>
                _LegacyQuoteCardStub(quote: quotes[index]),
          ),
      ],
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final QuoteHistoryFilter active;
  final ValueChanged<QuoteHistoryFilter> onChanged;
  const _FilterTabs({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: QuoteHistoryFilter.values.map((f) {
        final isSelected = active == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(f),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _kOrange : _kSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                f.name.toUpperCase(),
                style: GoogleFonts.publicSans(
                  color: isSelected ? Colors.white : _kMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final ClientEntity client;
  const _BottomActions({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder.withValues(alpha: 0.5))),
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to step 1 with pre-filled name logic would go here
            // For now just standard new quote
            context.push('/new-quote/step1');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: _kOrange.withValues(alpha: 0.4),
          ),
          child: Text(
            'Create New Quote for ${client.name.split(' ').first}',
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets & Menu ──────────────────────────────────────────────────────

class _MenuButton extends ConsumerWidget {
  final ClientEntity client;
  const _MenuButton({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      color: _kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) async {
        if (val == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddEditClientSheet(client: client),
          );
        } else if (val == 'delete') {
          final notifier = ref.read(clientProvider.notifier);
          final count = await notifier.getClientQuoteCount(client.id);

          if (!context.mounted) return;

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _kSurface,
              title: Text(
                'Delete Client?',
                style: GoogleFonts.publicSans(color: Colors.white),
              ),
              content: Text(
                count > 0
                    ? 'This client has $count quotes. Deleting will NOT delete their quotes. Continue?'
                    : 'Are you sure you want to delete this client?',
                style: GoogleFonts.publicSans(color: _kMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: _kMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await notifier.deleteClient(client.id);
            if (context.mounted) {
              context.go('/home/clients');
            }
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit Client', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete Client',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class _LegacyQuoteCardStub extends StatelessWidget {
  final QuoteEntity quote;
  const _LegacyQuoteCardStub({required this.quote});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');
    final date = DateFormat('dd MMM yyyy').format(quote.createdAt);

    return GestureDetector(
      onTap: () => context.push('/quote-detail/${quote.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#QT-${quote.quoteNumber.toString().padLeft(4, '0')}',
                  style: GoogleFonts.jetBrainsMono(
                    color: _kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quote.jobType,
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.publicSans(color: _kMuted, fontSize: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusPill(status: quote.status),
                const SizedBox(height: 8),
                Text(
                  currency.format(quote.totalAmount),
                  style: GoogleFonts.jetBrainsMono(
                    color: _kOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'accepted'
        ? _kGreen
        : (status == 'rejected' ? _kRose : _kAmber);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.publicSans(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


