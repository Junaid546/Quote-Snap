import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/quote_repository.dart';
import '../../domain/entities/quote_entity.dart';

// ─── Stats Data Class ─────────────────────────────────────────────────────────

class StatsData {
  final List<MapEntry<String, double>>
  monthlyRevenue; // Last 6 months (oldest first)
  final int acceptedQuotes;
  final int pendingQuotes;
  final int rejectedQuotes;
  final double winRate;
  final List<MapEntry<String, int>> jobTypes; // Sorted by count DESC
  final double averageQuoteValue;
  final int quotesThisMonth;
  final double bestMonthRevenue;

  const StatsData({
    required this.monthlyRevenue,
    required this.acceptedQuotes,
    required this.pendingQuotes,
    required this.rejectedQuotes,
    required this.winRate,
    required this.jobTypes,
    required this.averageQuoteValue,
    required this.quotesThisMonth,
    required this.bestMonthRevenue,
  });

  factory StatsData.empty() {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - 5 + i, 1);
      return MapEntry(DateFormat('MMM').format(date).toUpperCase(), 0.0);
    });

    return StatsData(
      monthlyRevenue: months,
      acceptedQuotes: 0,
      pendingQuotes: 0,
      rejectedQuotes: 0,
      winRate: 0.0,
      jobTypes: const [],
      averageQuoteValue: 0.0,
      quotesThisMonth: 0,
      bestMonthRevenue: 0.0,
    );
  }
}

// ─── Stats computations ───────────────────────────────────────────────────────

StatsData _computeStats(List<QuoteEntity> quotes) {
  if (quotes.isEmpty) return StatsData.empty();

  final now = DateTime.now();
  final currentMonthStart = DateTime(now.year, now.month, 1);
  final sixMonthsAgoStart = DateTime(now.year, now.month - 5, 1);

  // Storage for metrics
  final Map<String, double> revenueByMonth = {};
  int accepted = 0;
  int pending = 0;
  int rejected = 0;
  int quotesThisMonth = 0;
  double totalAcceptedValue = 0;
  final Map<String, int> jobsMap = {};

  // Initialize revenue map with last 6 months to ensure zeroes for missing months
  for (int i = 0; i < 6; i++) {
    final date = DateTime(now.year, now.month - 5 + i, 1);
    final key = DateFormat('MMM yyyy').format(date); // e.g., "Jan 2026"
    revenueByMonth[key] = 0.0;
  }

  for (final q in quotes) {
    // Basic counts
    if (q.status == 'accepted') {
      accepted++;
      totalAcceptedValue += q.totalAmount;

      // Revenue by month (only accepted quotes)
      if (q.createdAt.isAfter(sixMonthsAgoStart) ||
          q.createdAt.isAtSameMomentAs(sixMonthsAgoStart)) {
        final mKey = DateFormat('MMM yyyy').format(q.createdAt);
        if (revenueByMonth.containsKey(mKey)) {
          revenueByMonth[mKey] = (revenueByMonth[mKey] ?? 0.0) + q.totalAmount;
        }
      }
    } else if (q.status == 'pending') {
      pending++;
    } else if (q.status == 'rejected') {
      rejected++;
    }

    // Quotes this month (any status)
    if (q.createdAt.isAfter(currentMonthStart) ||
        q.createdAt.isAtSameMomentAs(currentMonthStart)) {
      quotesThisMonth++;
    }

    // Job types count
    final jt = q.jobType.trim();
    if (jt.isNotEmpty) {
      jobsMap[jt] = (jobsMap[jt] ?? 0) + 1;
    }
  }

  // Format revenue map for chart (list of entries, short month name)
  final monthlyRevenueList = revenueByMonth.entries.map((e) {
    final shortMonth = e.key
        .substring(0, 3)
        .toUpperCase(); // "JAN 2026" -> "JAN"
    return MapEntry(shortMonth, e.value);
  }).toList();

  // Find best month revenue (from the 6 months)
  double bestRevenue = 0.0;
  for (final val in revenueByMonth.values) {
    if (val > bestRevenue) bestRevenue = val;
  }

  // Sort job types
  final jobTypesList = jobsMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Averages and rates
  final totalQuotes = accepted + pending + rejected;
  final winRate = totalQuotes > 0 ? (accepted / totalQuotes) * 100 : 0.0;
  final avgValue = accepted > 0 ? (totalAcceptedValue / accepted) : 0.0;

  return StatsData(
    monthlyRevenue: monthlyRevenueList,
    acceptedQuotes: accepted,
    pendingQuotes: pending,
    rejectedQuotes: rejected,
    winRate: winRate,
    jobTypes: jobTypesList.take(5).toList(), // Limit to top 5
    averageQuoteValue: avgValue,
    quotesThisMonth: quotesThisMonth,
    bestMonthRevenue: bestRevenue,
  );
}

// ─── Stats Provider ───────────────────────────────────────────────────────────

final statsProvider = StreamProvider<StatsData>((ref) {
  final repo = ref.watch(quoteRepositoryProvider);
  return repo.watchQuotes().map((quotes) => _computeStats(quotes));
});
