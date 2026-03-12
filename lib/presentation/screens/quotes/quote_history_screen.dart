import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/quote_entity.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/quote_history_provider.dart';
import '../../widgets/loading/shimmer_widgets.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);
const _kMuted2 = Color(0xFF475569);

const _kAmber = Color(0xFFF59E0B);
const _kEmerald = Color(0xFF10B981);
const _kRose = Color(0xFFF43F5E);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class QuoteHistoryScreen extends ConsumerStatefulWidget {
  const QuoteHistoryScreen({super.key});

  @override
  ConsumerState<QuoteHistoryScreen> createState() => _QuoteHistoryScreenState();
}

class _QuoteHistoryScreenState extends ConsumerState<QuoteHistoryScreen> {
  final _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(quoteHistoryProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final initials =
        profileAsync.whenOrNull(
          data: (p) {
            if (p == null) return 'U';
            final parts = p.ownerName.trim().split(' ');
            if (parts.length >= 2) {
              return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            }
            return p.ownerName.isNotEmpty ? p.ownerName[0].toUpperCase() : 'U';
          },
        ) ??
        'U';

    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _BuildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            _Header(initials: initials),

            // ── Search Bar ───────────────────────────────────────────────────
            _SearchBar(
              controller: _searchController,
              resultCount: _searchActive
                  ? historyState.filteredQuotes.length
                  : null,
              onChanged: (v) {
                setState(() => _searchActive = v.trim().isNotEmpty);
                ref.read(quoteHistoryProvider.notifier).search(v);
              },
              onClear: () {
                _searchController.clear();
                setState(() => _searchActive = false);
                ref.read(quoteHistoryProvider.notifier).search('');
              },
            ),

            // ── Filter Tabs ──────────────────────────────────────────────────
            _FilterTabs(state: historyState),

            // ── Swipe Hint Bar ───────────────────────────────────────────────
            _SwipeHintBar(),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: historyState.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: 4,
                      itemBuilder: (_, __) => const QuoteCardShimmer(),
                    )
                  : historyState.filteredQuotes.isEmpty
                  ? _EmptyState(
                      hasSearch:
                          _searchActive ||
                          historyState.activeFilter != QuoteHistoryFilter.all,
                    )
                  : _QuoteList(quotes: historyState.filteredQuotes),
            ),

            const SizedBox(height: 80), // FAB clearance
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String initials;
  const _Header({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kOrange, Color(0xFFE85D25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'My Quotes',
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.publicSans(
                    color: _kOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final int? resultCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.terminal, color: _kMuted, size: 18),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'QUERY_DATABASE: search_quotes...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: _kMuted,
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      isDense: true,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.close, color: _kMuted, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          if (resultCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                '$resultCount result${resultCount == 1 ? '' : 's'} found',
                style: GoogleFonts.jetBrainsMono(color: _kMuted, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Filter Tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends ConsumerWidget {
  final QuoteHistoryState state;
  const _FilterTabs({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = [
      (QuoteHistoryFilter.all, 'ALL', state.countAll),
      (QuoteHistoryFilter.pending, 'PENDING', state.countPending),
      (QuoteHistoryFilter.accepted, 'ACCEPTED', state.countAccepted),
      (QuoteHistoryFilter.rejected, 'REJECTED', state.countRejected),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final (filter, label, count) = tabs[i];
          final isActive = state.activeFilter == filter;
          return GestureDetector(
            onTap: () =>
                ref.read(quoteHistoryProvider.notifier).setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isActive ? Colors.white : _kBorder),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.publicSans(
                      color: isActive ? _kBg : _kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? _kBg : _kSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.jetBrainsMono(
                        color: isActive ? Colors.white : _kMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Swipe Hint Bar ───────────────────────────────────────────────────────────

class _SwipeHintBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '[SYS_INFO: SWIPE_R_DUPLICATE]',
            style: GoogleFonts.jetBrainsMono(color: _kMuted2, fontSize: 9),
          ),
          Text(
            '[SYS_INFO: SWIPE_L_DELETE]',
            style: GoogleFonts.jetBrainsMono(color: _kMuted2, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ─── Quote List ───────────────────────────────────────────────────────────────

class _QuoteList extends ConsumerWidget {
  final List<QuoteEntity> quotes;
  const _QuoteList({required this.quotes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: quotes.length,
      itemBuilder: (context, i) {
        final quote = quotes[i];
        return _SwipeableQuoteCard(quote: quote, key: ValueKey(quote.id));
      },
    );
  }
}

// ─── Swipeable Card Wrapper ───────────────────────────────────────────────────

class _SwipeableQuoteCard extends ConsumerWidget {
  final QuoteEntity quote;
  const _SwipeableQuoteCard({required this.quote, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(quote.id),
        // ── Left action (delete) ─────────────────────────────────────────────
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) => _onDelete(context, ref),
              backgroundColor: _kRose,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              borderRadius: BorderRadius.circular(14),
              label: 'Delete',
            ),
          ],
        ),
        // ── Right action (duplicate) ─────────────────────────────────────────
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) => _onDuplicate(context, ref),
              backgroundColor: _kAmber,
              foregroundColor: Colors.white,
              icon: Icons.copy_outlined,
              borderRadius: BorderRadius.circular(14),
              label: 'Copy',
            ),
          ],
        ),
        child: _QuoteCard(
          quote: quote,
          onTap: () => context.push('/quote-detail/${quote.id}'),
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(quoteNumber: quote.quoteNumber),
    );
    if (confirmed == true) {
      ref.read(quoteHistoryProvider.notifier).deleteQuote(quote.id);
    }
  }

  Future<void> _onDuplicate(BuildContext context, WidgetRef ref) async {
    final newNumber = await ref
        .read(quoteHistoryProvider.notifier)
        .duplicateQuote(quote.id);
    if (context.mounted && newNumber != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quote duplicated as #${newNumber.toString().padLeft(4, '0')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}

// ─── Quote Card ───────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  final QuoteEntity quote;
  final VoidCallback onTap;
  const _QuoteCard({required this.quote, required this.onTap});

  Color get _statusColor {
    return switch (quote.status) {
      'accepted' => _kEmerald,
      'rejected' => _kRose,
      _ => _kAmber,
    };
  }

  String get _statusLabel => switch (quote.status) {
    'accepted' => 'ACCEPTED',
    'rejected' => 'REJECTED',
    _ => 'PENDING',
  };

  IconData get _jobIcon => switch (quote.jobType.toLowerCase()) {
    final s when s.contains('electric') => Icons.bolt_rounded,
    final s when s.contains('plumb') => Icons.water_drop_rounded,
    final s when s.contains('paint') => Icons.format_paint_rounded,
    final s when s.contains('roof') => Icons.roofing_rounded,
    final s when s.contains('floor') => Icons.grid_on_rounded,
    final s when s.contains('hvac') || s.contains('air') => Icons.air_rounded,
    final s when s.contains('fence') => Icons.fence_rounded,
    _ => Icons.construction_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');
    final dateStr = DateFormat(
      'dd_MMM_yyyy',
    ).format(quote.createdAt).toUpperCase();

    return Opacity(
      opacity: quote.status == 'rejected' ? 0.7 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder.withValues(alpha: 0.6)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left border strip
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                // Card body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quote number + status badge row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '#QT-${quote.quoteNumber.toString().padLeft(4, '0')}',
                              style: GoogleFonts.jetBrainsMono(
                                color: _kMuted,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            _StatusBadge(
                              label: _statusLabel,
                              color: _statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Client name
                        Text(
                          quote.clientName,
                          style: GoogleFonts.publicSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Job type row
                        Row(
                          children: [
                            Icon(_jobIcon, color: _kMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              quote.jobType,
                              style: GoogleFonts.publicSans(
                                color: _kMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date + amount row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: _kMuted,
                                  size: 11,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: _kMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.publicSans(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Delete Confirm Dialog ────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final int quoteNumber;
  const _DeleteConfirmDialog({required this.quoteNumber});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kRose.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: _kRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Delete Quote',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'Delete quote #${quoteNumber.toString().padLeft(4, '0')}?\nThis cannot be undone.',
        style: GoogleFonts.publicSans(
          color: _kMuted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
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

// Removing unused Shimmer classes

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _kSurface,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: _kMuted,
                  size: 34,
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: _kBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: _kOrange,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No quotes found',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search or filter'
                : 'Tap + to create your first quote',
            style: GoogleFonts.publicSans(color: _kMuted, fontSize: 13),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push('/new-quote/step1'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kOrange, Color(0xFFE85D25)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Quote',
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _BuildFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/new-quote/step1'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kOrange, Color(0xFFE85D25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _kOrange.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
