import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/subscription_provider.dart';

// IMPORTANT: This is a UI simulation only.
// In production, integrate RevenueCat for mobile subscriptions:
// https://www.revenuecat.com/
// Or Stripe for web: https://stripe.com/
// NEVER process real card data in Flutter directly.
// This simulation only demonstrates the UX flow.

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);
const _kGreen = Color(0xFF22C55E);

class PaymentSheet extends ConsumerStatefulWidget {
  final String plan;
  const PaymentSheet({super.key, required this.plan});

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isProcessing = false;
  bool _isSuccess = false;

  late AnimationController _checkController;
  late Animation<double> _checkScale;

  String get _planLabel => widget.plan == 'pro' ? 'Pro' : 'Team';
  String get _planPrice => widget.plan == 'pro' ? '\$25.00' : '\$45.00';

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _onPay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Simulate 2.5 second delay
    await Future.delayed(const Duration(milliseconds: 2500));

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
    _checkController.forward();

    // Upgrade subscription
    if (widget.plan == 'pro') {
      await ref.read(subscriptionProvider.notifier).upgradeToPro();
    } else {
      await ref.read(subscriptionProvider.notifier).upgradeToTeam();
    }

    // Wait 1.5 seconds then close
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pop(context); // close sheet
      Navigator.pop(context); // close upgrade screen

      // Show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 You\'re now on $_planLabel! Unlimited quotes unlocked.',
            style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: _isSuccess ? _kGreen.withValues(alpha: 0.95) : _kBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: _isSuccess
            ? _buildSuccess(scrollController)
            : _buildForm(scrollController),
      ),
    );
  }

  Widget _buildSuccess(ScrollController sc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.check_rounded, color: _kGreen, size: 60),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful! 🎉',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome to QuoteSnap $_planLabel',
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ScrollController sc) {
    return Column(
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
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Upgrade',
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'QuoteSnap $_planLabel • $_planPrice/month',
                style: GoogleFonts.publicSans(
                  color: _kOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              children: [
                // Card Number
                const _FormLabel('CARD NUMBER'),
                const SizedBox(height: 8),
                _CardNumberField(controller: _cardController),
                const SizedBox(height: 20),

                // Expiry + CVV
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FormLabel('EXPIRY'),
                          const SizedBox(height: 8),
                          _ExpiryField(controller: _expiryController),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FormLabel('CVV'),
                          const SizedBox(height: 8),
                          _CvvField(controller: _cvvController),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Cardholder Name
                const _FormLabel('CARDHOLDER NAME'),
                const SizedBox(height: 8),
                _NameField(controller: _nameController),
                const SizedBox(height: 40),

                // Pay Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: _kOrange.withValues(alpha: 0.5),
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Processing...',
                                style: GoogleFonts.publicSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'PAY $_planPrice',
                            style: GoogleFonts.publicSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🔒 Your payment info is never stored on-device.\nThis demo simulates payment — no real charge occurs.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: _kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Form Helpers ─────────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.publicSans(
        color: _kMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

InputDecoration _fieldDec({String? hint, IconData? prefix, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.publicSans(color: _kMuted, fontSize: 14),
      prefixIcon: prefix != null
          ? Icon(prefix, color: _kMuted, size: 20)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: _kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );

const _kStyle = TextStyle(color: Colors.white, fontSize: 16);

class _CardNumberField extends StatelessWidget {
  final TextEditingController controller;
  const _CardNumberField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: _kStyle,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CardNumberFormatter(),
      ],
      validator: (v) {
        final digits = v?.replaceAll(' ', '') ?? '';
        return digits.length == 16
            ? null
            : 'Enter a valid 16-digit card number';
      },
      decoration: _fieldDec(
        hint: '•••• •••• •••• 1234',
        prefix: Icons.credit_card_rounded,
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryField extends StatelessWidget {
  final TextEditingController controller;
  const _ExpiryField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: _kStyle,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        _ExpiryFormatter(),
      ],
      validator: (v) {
        if (v == null || !v.contains('/') || v.length < 5) return 'MM/YY';
        return null;
      },
      decoration: _fieldDec(hint: 'MM/YY'),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    if (text.length == 2 && oldValue.text.length < 2) text = '$text/';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CvvField extends StatelessWidget {
  final TextEditingController controller;
  const _CvvField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      style: _kStyle,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        if (v == null || v.length < 3) return 'Invalid CVV';
        return null;
      },
      decoration: _fieldDec(hint: '•••').copyWith(counterText: ''),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: _kStyle,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: _fieldDec(
        hint: 'John Smith',
        prefix: Icons.person_outline_rounded,
      ),
    );
  }
}
