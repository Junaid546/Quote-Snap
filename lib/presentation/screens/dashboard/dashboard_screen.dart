import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/error_handler.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/sync_indicator.dart';
import '../../widgets/loading/shimmer_widgets.dart';
import '../../widgets/subscription/paywall_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch data streams
    final userProfileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentQuotesAsync = ref.watch(recentQuotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF14161F),
      drawer: const Drawer(
        backgroundColor: Color(0xFF1C1F2A),
        child: Center(
          child: Text(
            'Menu Placeholder',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14161F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'QuoteSnap',
          style: GoogleFonts.outfit(
            color: const Color(0xFFEC5B13),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => context.push('/home/settings'),
              child: userProfileAsync.when(
                data: (profile) {
                  final logoPath = profile?.logoPath;
                  if (logoPath != null && logoPath.isNotEmpty) {
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: FileImage(File(logoPath)),
                      backgroundColor: const Color(0xFF2A2D3E),
                    );
                  }
                  return const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF2A2D3E),
                    child: Icon(Icons.person, color: Colors.white70, size: 20),
                  );
                },
                loading: () => const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF2A2D3E),
                  child: Icon(Icons.person, color: Colors.white70, size: 20),
                ),
                error: (_, __) => const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF2A2D3E),
                  child: Icon(Icons.person, color: Colors.white70, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Sync Indicator (slides in when relevant) ──
          const SyncIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  userProfileAsync.when(
                    data: (profile) {
                      final name = profile?.ownerName ?? 'There';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $name 👋',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Here's what's happening today.",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const DashboardShimmer(),
                    error: (err, stack) => AppErrorWidget(
                      error: mapError(err, stack),
                      onRetry: () => ref.refresh(userProfileProvider),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards Row
                  statsAsync.when(
                    data: (stats) => Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Sent',
                            value: stats.quotesThisMonth.toString(),
                            valueColor: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Accepted',
                            value: stats.acceptedThisMonth.toString(),
                            valueColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Earnings',
                            value: '\$${stats.earningsThisMonth.toInt()}',
                            valueColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => SizedBox(
                      height: 90,
                      child: Center(child: Text('Error: $err')),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // NEW QUOTE Button with paywall enforcement
                  _NewQuoteButton(),
                  const SizedBox(height: 36),

                  // Recent Quotes Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Quotes',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(
                          '/home/quotes',
                        ), // Assuming tab 1 is quotes tab
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFFEC5B13),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recent Quotes List
                  recentQuotesAsync.when(
                    data: (quotes) {
                      if (quotes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1F2A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'No quotes yet. Create your first one!',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quotes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          return _RecentQuoteCard(
                            id: quote.id,
                            clientName: quote.clientName,
                            jobType: quote.jobType,
                            amount: quote.totalAmount,
                            status: quote.status,
                            dateMillis: quote.createdAt,
                          );
                        },
                      );
                    },
                    loading: () => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, __) => const QuoteCardShimmer(),
                    ),
                    error: (err, stack) => AppErrorWidget(
                      error: mapError(err, stack),
                      onRetry: () => ref.refresh(recentQuotesProvider),
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: 20), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Component: New Quote Button with Paywall ─────────────────────────────────

class _NewQuoteButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);
    final sub = subAsync.valueOrNull;
    final isFree = sub?.isFree ?? true;
    final quotesUsed = sub?.quotesUsed ?? 0;
    final quotesLimit = sub?.currentPlan.quoteLimit ?? 5;

    void onTap() async {
      // Check limit on every tap
      final canCreate = await ref
          .read(subscriptionProvider.notifier)
          .checkQuoteLimit();
      if (canCreate) {
        if (context.mounted) context.push('/new-quote/step1');
      } else {
        if (context.mounted) {
          showDialog(context: context, builder: (_) => const PaywallDialog());
        }
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF97316).withAlpha(100),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'NEW QUOTE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Usage counter for free users
        if (isFree) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$quotesUsed of $quotesLimit free quotes used',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: quotesLimit > 0
                  ? (quotesUsed / quotesLimit).clamp(0.0, 1.0)
                  : 1.0,
              minHeight: 4,
              backgroundColor: const Color(0xFF2A2D3E),
              color: quotesUsed >= quotesLimit
                  ? Colors.redAccent
                  : const Color(0xFFEC5B13),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Component: Stat Card ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: valueColor,
              fontSize:
                  24, // Adjusted from 32 down to 24 to fit better on small screens
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Component: Recent Quote Card ────────────────────────────────────────────

class _RecentQuoteCard extends StatelessWidget {
  final String id;
  final String clientName;
  final String jobType;
  final double amount;
  final String status;
  final int dateMillis;

  const _RecentQuoteCard({
    required this.id,
    required this.clientName,
    required this.jobType,
    required this.amount,
    required this.status,
    required this.dateMillis,
  });

  @override
  Widget build(BuildContext context) {
    // Basic mapping of job types to icons
    IconData getJobIcon(String type) {
      final t = type.toLowerCase();
      if (t.contains('plumb')) return Icons.plumbing;
      if (t.contains('electric')) return Icons.electrical_services;
      if (t.contains('paint')) return Icons.format_paint;
      if (t.contains('roof')) return Icons.roofing;
      if (t.contains('hvac') || t.contains('heat') || t.contains('cool')) {
        return Icons.hvac;
      }
      return Icons.handyman;
    }

    final dateStr = DateFormat(
      'MMM d, yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(dateMillis));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/quote-detail/$id'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1F2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          child: Row(
            children: [
              // Left Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC5B13).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getJobIcon(jobType),
                  color: const Color(0xFFEC5B13),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Center Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusPill(status: status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Component: Status Pill ──────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'paid':
        bgColor = Colors.green.withAlpha(50);
        textColor = Colors.greenAccent.shade400;
        borderColor = Colors.green.withAlpha(100);
        break;
      case 'rejected':
        bgColor = Colors.red.withAlpha(50);
        textColor = Colors.redAccent.shade200;
        borderColor = Colors.red.withAlpha(100);
        break;
      case 'pending':
      default:
        bgColor = Colors.amber.withAlpha(50);
        textColor = Colors.amberAccent.shade400;
        borderColor = Colors.transparent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: borderColor == Colors.transparent ? 0 : 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
