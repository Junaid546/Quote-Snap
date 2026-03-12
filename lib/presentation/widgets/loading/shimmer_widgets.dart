import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

const _kBaseColor = Color(0xFF1C1F2A);
const _kHighColor = Color(0xFF2A2D3A);
const _kSurface = Color(0xFF1E2130);

// ─── Shared Shimmer Box ───────────────────────────────────────────────────────

Widget _box(double w, double h, {double radius = 8}) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: _kBaseColor,
    borderRadius: BorderRadius.circular(radius),
  ),
);

Widget _shimmer(Widget child) => Shimmer.fromColors(
  baseColor: _kBaseColor,
  highlightColor: _kHighColor,
  child: child,
);

// ─── Quote Card Shimmer ───────────────────────────────────────────────────────

class QuoteCardShimmer extends StatelessWidget {
  const QuoteCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_box(120, 14), _box(60, 24, radius: 12)],
            ),
            const SizedBox(height: 10),
            _box(180, 12),
            const SizedBox(height: 6),
            _box(100, 12),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_box(80, 20), _box(60, 12)],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Client Card Shimmer ──────────────────────────────────────────────────────

class ClientCardShimmer extends StatelessWidget {
  const ClientCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _kBaseColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(140, 14),
                  const SizedBox(height: 8),
                  _box(100, 12),
                  const SizedBox(height: 6),
                  _box(80, 12),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [_box(70, 18), const SizedBox(height: 6), _box(50, 12)],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card Shimmer ────────────────────────────────────────────────────────

class StatCardShimmer extends StatelessWidget {
  const StatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _shimmer(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_box(60, 11), const SizedBox(height: 8), _box(90, 24)],
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Shimmer ────────────────────────────────────────────────────────

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting section
            _box(180, 28, radius: 10),
            const SizedBox(height: 8),
            _box(120, 14, radius: 6),
            const SizedBox(height: 24),

            // Stat cards row 1
            const Row(
              children: [
                StatCardShimmer(),
                SizedBox(width: 12),
                StatCardShimmer(),
              ],
            ),
            const SizedBox(height: 12),
            // Stat cards row 2
            const Row(
              children: [
                StatCardShimmer(),
                SizedBox(width: 12),
                StatCardShimmer(),
              ],
            ),
            const SizedBox(height: 28),

            // NEW QUOTE button shimmer
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _kBaseColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 28),

            // Section header
            _box(100, 16, radius: 6),
            const SizedBox(height: 16),

            // Recent quote cards
            for (int i = 0; i < 4; i++) ...[
              const QuoteCardShimmer(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
