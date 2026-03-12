import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/settings_provider.dart';

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);

class SubscriptionBottomSheet extends ConsumerWidget {
  const SubscriptionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final profile = state.valueOrNull?.profile;
    final currentPlan = profile?.subscriptionPlan ?? 'free';

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Subscription',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  _PlanCard(
                    title: 'Free Plan',
                    price: 'Free',
                    description:
                        'Up to 5 quotes per month, standard templates.',
                    isActive: currentPlan == 'free',
                    features: const [
                      '5 Quotes/month',
                      'Standard Templates',
                      'Basic CRM',
                    ],
                    onSelect: currentPlan == 'free'
                        ? null
                        : () => _update(context, ref, 'free'),
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    title: 'Pro Plan',
                    price: '\$25.00/mo',
                    description:
                        'Unlimited quotes, premium templates, CSV exports, analytics.',
                    isActive: currentPlan == 'pro',
                    features: const [
                      'Unlimited Quotes',
                      'Premium Templates',
                      'Priority Support',
                      'Data Export',
                    ],
                    onSelect: currentPlan == 'pro'
                        ? null
                        : () => _update(context, ref, 'pro'),
                    isFeatured: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _update(BuildContext context, WidgetRef ref, String plan) async {
    await ref.read(settingsProvider.notifier).updateSubscriptionPlan(plan);
    if (context.mounted) Navigator.pop(context);
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final bool isActive;
  final bool isFeatured;
  final List<String> features;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.description,
    required this.isActive,
    required this.features,
    this.isFeatured = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? _kOrange
              : (isFeatured ? _kOrange.withValues(alpha: 0.5) : _kBorder),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: _kOrange.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CURRENT',
                    style: GoogleFonts.publicSans(
                      color: _kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: GoogleFonts.jetBrainsMono(
              color: isFeatured ? _kOrange : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.publicSans(color: _kMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: isFeatured ? _kOrange : _kMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: GoogleFonts.publicSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? _kBorder
                    : (isFeatured ? _kOrange : _kSurface),
                side: isActive
                    ? null
                    : BorderSide(color: isFeatured ? _kOrange : _kBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isActive
                    ? 'Current Plan'
                    : (isFeatured ? 'Upgrade to Pro' : 'Downgrade to Free'),
                style: GoogleFonts.publicSans(
                  color: isActive ? _kMuted : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
