import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/error_handler.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/common/app_error_widget.dart';

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);
const _kEmerald = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kRose = Color(0xFFF43F5E);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: statsAsync.when(
                data: (data) => _buildContent(context, data),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _kOrange),
                ),
                error: (err, stack) =>
                    AppErrorWidget(error: mapError(err, stack)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monthStr,
                style: GoogleFonts.jetBrainsMono(
                  color: _kOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _kOrange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x66FF6B35),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('REVENUE (LAST 6 MONTHS)'),
          const SizedBox(height: 12),
          _RevenueChart(data: data),
          const SizedBox(height: 32),
          const _SectionTitle('QUOTE STATUS'),
          const SizedBox(height: 12),
          _StatusChart(data: data),
          const SizedBox(height: 32),
          const _SectionTitle('TOP JOB TYPES'),
          const SizedBox(height: 12),
          _JobTypesChart(data: data),
          const SizedBox(height: 32),
          const _SectionTitle('SUMMARY STATS'),
          const SizedBox(height: 12),
          _SummaryGrid(data: data),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── UI Helpers ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.publicSans(
        color: _kMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─── Revenue Line Chart ───────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final StatsData data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.monthlyRevenue.isEmpty || data.bestMonthRevenue == 0) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Not enough data to graph.\nWin some quotes to see revenue!',
            style: GoogleFonts.publicSans(color: _kMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxY = ((data.bestMonthRevenue / 1000).ceil() * 1000)
        .toDouble()
        .clamp(100.0, double.infinity);

    return Container(
      height: 240,
      padding: const EdgeInsets.only(right: 16, top: 24, bottom: 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final month = data.monthlyRevenue[spot.x.toInt()].key;
                  final val = NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(spot.y);
                  return LineTooltipItem(
                    '$month\n$val',
                    GoogleFonts.publicSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: _kBorder.withValues(alpha: 0.5), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= 6) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data.monthlyRevenue[idx].key,
                      style: GoogleFonts.jetBrainsMono(
                        color: _kMuted,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (val, meta) {
                  if (val == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '\$${NumberFormat.compact().format(val)}',
                      style: GoogleFonts.jetBrainsMono(
                        color: _kMuted,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.monthlyRevenue.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.value);
              }).toList(),
              isCurved: true,
              color: _kOrange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _kOrange.withValues(alpha: 0.2),
                    _kOrange.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Do-nut Chart ──────────────────────────────────────────────────────

class _StatusChart extends StatelessWidget {
  final StatsData data;
  const _StatusChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total =
        data.acceptedQuotes + data.pendingQuotes + data.rejectedQuotes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: total == 0
                        ? [
                            PieChartSectionData(
                              color: _kBorder,
                              value: 1,
                              showTitle: false,
                              radius: 24,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              color: _kEmerald,
                              value: data.acceptedQuotes.toDouble(),
                              showTitle: false,
                              radius: 24,
                            ),
                            PieChartSectionData(
                              color: _kAmber,
                              value: data.pendingQuotes.toDouble(),
                              showTitle: false,
                              radius: 24,
                            ),
                            PieChartSectionData(
                              color: _kRose,
                              value: data.rejectedQuotes.toDouble(),
                              showTitle: false,
                              radius: 24,
                            ),
                          ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Win Rate',
                        style: GoogleFonts.publicSans(
                          color: _kMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${data.winRate.toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(
                color: _kEmerald,
                label: 'Accepted',
                count: data.acceptedQuotes,
              ),
              _LegendItem(
                color: _kAmber,
                label: 'Pending',
                count: data.pendingQuotes,
              ),
              _LegendItem(
                color: _kRose,
                label: 'Rejected',
                count: data.rejectedQuotes,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: GoogleFonts.publicSans(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Job Types Bar Chart ──────────────────────────────────────────────────────

class _JobTypesChart extends StatelessWidget {
  final StatsData data;
  const _JobTypesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.jobTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No job data yet.',
          style: GoogleFonts.publicSans(color: _kMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    final maxCount = data.jobTypes.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: data.jobTypes.map((job) {
          final fraction = maxCount == 0 ? 0.0 : job.value / maxCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    job.key,
                    style: GoogleFonts.publicSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kOrange, Color(0xFFE85D25)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${job.value}',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Summary Metrics Grid ─────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final StatsData data;
  const _SummaryGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _MetricCard(
          'Avg Value',
          cur.format(data.averageQuoteValue),
          Icons.request_quote_rounded,
        ),
        _MetricCard(
          'This Month',
          '${data.quotesThisMonth}',
          Icons.calendar_today_rounded,
        ),
        _MetricCard(
          'Best Month',
          cur.format(data.bestMonthRevenue),
          Icons.emoji_events_rounded,
        ),
        _MetricCard(
          'Accept Rate',
          '${data.winRate.toStringAsFixed(1)}%',
          Icons.check_circle_rounded,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MetricCard(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: _kOrange, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.publicSans(
                  color: _kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
