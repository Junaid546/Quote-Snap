import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/subscription/payment_sheet.dart';

const _kBg = Color(0xFF0A0E1A);
const _kCard = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showPaymentSheet(String plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient glow
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kOrange.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              children: [
                // ─── Top Bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBorder),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // ─── Hero ────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt, color: _kOrange, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              'QUOTESNAP PRO',
                              style: GoogleFonts.barlowCondensed(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Close more jobs. Earn more money.',
                          style: GoogleFonts.dmSans(
                            color: _kMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ─── Plan Cards ──────────────────────────────────
                        _FreePlanCard(),
                        const SizedBox(height: 16),
                        _ProPlanCard(onUpgrade: () => _showPaymentSheet('pro')),
                        const SizedBox(height: 16),
                        _TeamPlanCard(
                          onUpgrade: () => _showPaymentSheet('team'),
                        ),
                        const SizedBox(height: 36),

                        // ─── CTA Button ───────────────────────────────────
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, child) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: child,
                          ),
                          child: GestureDetector(
                            onTap: () => _showPaymentSheet('pro'),
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFE85D25),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kOrange.withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'UPGRADE TO PRO — \$25/month',
                                  style: GoogleFonts.publicSans(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '🔒 Secure payment • Cancel anytime • 7-day free trial',
                          style: GoogleFonts.dmSans(
                            color: _kMuted,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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

// ─── Free Plan Card ───────────────────────────────────────────────────────────

class _FreePlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _PlanCard(
      badgeLabel: 'FREE',
      badgeColor: _kMuted,
      title: 'Free Tier',
      price: '\$0',
      period: '/month',
      borderColor: _kBorder,
      shadowColor: Colors.transparent,
      features: [
        _Feature('5 quotes / month', true),
        _Feature('Basic PDF generation', true),
        _Feature('Email support', true),
        _Feature('Unlimited quotes', false),
        _Feature('WhatsApp sending', false),
        _Feature('Client CRM', false),
        _Feature('Cloud sync (Firebase)', false),
      ],
      ctaLabel: null,
    );
  }
}

// ─── Pro Plan Card ────────────────────────────────────────────────────────────

class _ProPlanCard extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _ProPlanCard({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return _PlanCard(
      badgeLabel: 'PRO',
      badgeColor: _kOrange,
      extraBadge: 'MOST POPULAR',
      title: 'Pro Plan',
      price: '\$25',
      period: '/month',
      borderColor: _kOrange,
      shadowColor: _kOrange.withValues(alpha: 0.2),
      isFeatured: true,
      features: const [
        _Feature('Unlimited quotes', true),
        _Feature('Professional PDF branding', true),
        _Feature('WhatsApp + Email sending', true),
        _Feature('Full Client CRM', true),
        _Feature('Cloud sync (Firebase)', true),
        _Feature('Quote analytics', true),
        _Feature('Priority support', true),
        _Feature('Export to CSV', true),
      ],
      ctaLabel: 'Upgrade to Pro',
      onCtaTap: onUpgrade,
    );
  }
}

// ─── Team Plan Card ───────────────────────────────────────────────────────────

class _TeamPlanCard extends StatelessWidget {
  final VoidCallback onUpgrade;
  const _TeamPlanCard({required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return _PlanCard(
      badgeLabel: 'TEAM',
      badgeColor: const Color(0xFF3B82F6),
      title: 'Team Plan',
      price: '\$45',
      period: '/month',
      borderColor: const Color(0xFF3B82F6).withValues(alpha: 0.5),
      shadowColor: Colors.transparent,
      features: const [
        _Feature('Everything in Pro', true),
        _Feature('Up to 3 team members', true),
        _Feature('Shared client database', true),
        _Feature('Admin dashboard', true),
      ],
      ctaLabel: 'Upgrade to Team',
      onCtaTap: onUpgrade,
    );
  }
}

// ─── Reusable Plan Card ───────────────────────────────────────────────────────

class _Feature {
  final String label;
  final bool included;
  const _Feature(this.label, this.included);
}

class _PlanCard extends StatelessWidget {
  final String badgeLabel;
  final Color badgeColor;
  final String? extraBadge;
  final String title;
  final String price;
  final String period;
  final Color borderColor;
  final Color shadowColor;
  final bool isFeatured;
  final List<_Feature> features;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const _PlanCard({
    required this.badgeLabel,
    required this.badgeColor,
    this.extraBadge,
    required this.title,
    required this.price,
    required this.period,
    required this.borderColor,
    required this.shadowColor,
    this.isFeatured = false,
    required this.features,
    this.ctaLabel,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: isFeatured ? 2 : 1),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 32, spreadRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.publicSans(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (extraBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    extraBadge!,
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.jetBrainsMono(
                  color: isFeatured ? _kOrange : Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  period,
                  style: GoogleFonts.dmSans(color: _kMuted, fontSize: 14),
                ),
              ),
            ],
          ),
          if (isFeatured)
            Text(
              'Billed monthly • Cancel anytime',
              style: GoogleFonts.dmSans(color: _kMuted, fontSize: 12),
            ),
          const SizedBox(height: 20),

          // Feature list
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    f.included
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: f.included
                        ? Colors.greenAccent.shade400
                        : Colors.red.withValues(alpha: 0.4),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    f.label,
                    style: GoogleFonts.publicSans(
                      color: f.included ? Colors.white : _kMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (ctaLabel != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onCtaTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFeatured ? _kOrange : _kCard,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  ctaLabel!,
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
