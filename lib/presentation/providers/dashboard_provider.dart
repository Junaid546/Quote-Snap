import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';

// Provides user profile stream for the dashboard greeting
final userProfileProvider = StreamProvider<UserProfileData?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.userProfile).watchSingleOrNull();
});

class DashboardStats {
  final int quotesThisMonth;
  final int acceptedThisMonth;
  final double earningsThisMonth;

  const DashboardStats({
    required this.quotesThisMonth,
    required this.acceptedThisMonth,
    required this.earningsThisMonth,
  });
}

// Computes statistics for the current month based on quotes
final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final db = ref.watch(databaseProvider);

  // Get start of current month as a timestamp (since we store it as int)
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

  return db.select(db.quotes).watch().map((quotes) {
    int quotesThisMonth = 0;
    int acceptedThisMonth = 0;
    double earningsThisMonth = 0.0;

    for (var quote in quotes) {
      // Check if quote is from this month
      if (quote.createdAt >= startOfMonth) {
        quotesThisMonth++;
        if (quote.status == 'accepted' || quote.status == 'paid') {
          acceptedThisMonth++;
          earningsThisMonth += quote.totalAmount;
        }
      }
    }

    return DashboardStats(
      quotesThisMonth: quotesThisMonth,
      acceptedThisMonth: acceptedThisMonth,
      earningsThisMonth: earningsThisMonth,
    );
  });
});

// Provides the 3 most recent quotes
final recentQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.quotes)
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ])
        ..limit(3))
      .watch();
});
