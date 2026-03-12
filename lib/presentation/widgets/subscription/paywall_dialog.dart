import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/subscription_provider.dart';

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);

/// A compact modal dialog shown when the user hits the free-tier quote limit.
class PaywallDialog extends ConsumerWidget {
  const PaywallDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider).valueOrNull;
    final used = sub?.quotesUsed ?? 5;
    final limit = sub?.currentPlan.quoteLimit ?? 5;

    return Dialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _kOrange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kOrange.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _kOrange,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Quote Limit Reached',
              style: GoogleFonts.publicSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Body
            Text(
              "You've used all $limit free quotes this month. Upgrade to Pro for unlimited quotes.",
              style: GoogleFonts.publicSans(
                color: _kMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Usage Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Usage',
                        style: GoogleFonts.publicSans(
                          color: _kMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$used/$limit quotes used',
                        style: GoogleFonts.jetBrainsMono(
                          color: _kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: limit > 0 ? (used / limit).clamp(0.0, 1.0) : 1.0,
                      minHeight: 8,
                      backgroundColor: _kBorder,
                      color: _kOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upgrade CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/upgrade');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'UPGRADE TO PRO',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Maybe Later
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.publicSans(color: _kMuted, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
