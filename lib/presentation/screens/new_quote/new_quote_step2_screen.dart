import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../providers/new_quote_provider.dart';
import '../../providers/dashboard_provider.dart';

class NewQuoteStep2Screen extends ConsumerStatefulWidget {
  const NewQuoteStep2Screen({super.key});

  @override
  ConsumerState<NewQuoteStep2Screen> createState() =>
      _NewQuoteStep2ScreenState();
}

class _NewQuoteStep2ScreenState extends ConsumerState<NewQuoteStep2Screen> {
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(newQuoteProvider);
    _clientController.text = state.clientName;
    _phoneController.text = state.clientPhone ?? '';
    _emailController.text = state.clientEmail ?? '';
    _rateController.text = state.laborRate.toStringAsFixed(0);
    _notesController.text = state.notes;

    // Pre-fill labor rate from user profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileAsync = ref.read(userProfileProvider);
      profileAsync.whenData((profile) {
        if (profile != null && state.laborRate == 0.0) {
          final rate = profile.defaultHourlyRate;
          _rateController.text = rate.toStringAsFixed(0);
          ref.read(newQuoteProvider.notifier).setLaborRate(rate);
        }
        if (profile != null && !state.applyTax) {
          ref
              .read(newQuoteProvider.notifier)
              .setTaxRate(profile.defaultTaxRate);
        }
      });
    });
  }

  @override
  void dispose() {
    _clientController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddItemSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1F2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Custom Item',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _DarkField(
                controller: nameCtrl,
                labelText: 'Item Name',
                hintText: 'e.g. Custom Part',
              ),
              const SizedBox(height: 14),
              _DarkField(
                controller: priceCtrl,
                labelText: 'Unit Price (\$)',
                hintText: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC5B13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    if (name.isNotEmpty && price > 0) {
                      ref
                          .read(newQuoteProvider.notifier)
                          .addCustomItem(name, price);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(
                    'Add Item',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onPreview() {
    final notifier = ref.read(newQuoteProvider.notifier);
    notifier.setClientName(_clientController.text.trim());
    notifier.setClientEmail(_emailController.text.trim());
    notifier.setLaborRate(
      double.tryParse(_rateController.text) ?? notifier.state.laborRate,
    );
    notifier.setNotes(_notesController.text.trim());
    context.push('/new-quote/step3');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newQuoteProvider);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const summaryHeight = 240.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'Build Quote',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '2 / 3',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFEC5B13),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Orange progress bar (66%)
          Container(
            height: 4,
            color: const Color(0xFF1C1F2A),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.66,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                summaryHeight + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Client Name ─────────────────────────────────────────
                  const _SectionLabel('Client Name'),
                  const SizedBox(height: 10),
                  _DarkField(
                    controller: _clientController,
                    labelText: '',
                    hintText: 'e.g. John Smith',
                    onChanged: (v) =>
                        ref.read(newQuoteProvider.notifier).setClientName(v),
                  ),
                  const SizedBox(height: 24),

                  const _SectionLabel('Client Contact (Optional)'),
                  const SizedBox(height: 10),
                  IntlPhoneField(
                    controller: _phoneController,
                    initialCountryCode: 'US',
                    disableLengthCheck: true,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    dropdownTextStyle: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    onChanged: (phone) {
                      final value = phone.number.trim().isEmpty
                          ? null
                          : phone.completeNumber;
                      ref
                          .read(newQuoteProvider.notifier)
                          .setClientPhone(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1C1F2A),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC5B13),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DarkField(
                    controller: _emailController,
                    labelText: '',
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (v) =>
                        ref.read(newQuoteProvider.notifier).setClientEmail(v),
                  ),
                  const SizedBox(height: 32),

                  // ── Materials ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('Materials'),
                      GestureDetector(
                        onTap: _showAddItemSheet,
                        child: const Text(
                          '+ Add Custom Item',
                          style: TextStyle(
                            color: Color(0xFFEC5B13),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1F2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'No materials loaded. Select a job type in Step 1 or add custom items.',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E), // Colors.grey.shade500
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1F2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: Color(0xFF2A2D3E),
                          height: 1,
                          indent: 56,
                        ),
                        itemBuilder: (ctx, i) {
                          return _MaterialRow(
                            item: state.items[i],
                            onToggle: () => ref
                                .read(newQuoteProvider.notifier)
                                .toggleItemChecked(i),
                            onDecrement: () => ref
                                .read(newQuoteProvider.notifier)
                                .setItemQuantity(
                                  i,
                                  state.items[i].quantity - 1,
                                ),
                            onIncrement: () => ref
                                .read(newQuoteProvider.notifier)
                                .setItemQuantity(
                                  i,
                                  state.items[i].quantity + 1,
                                ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),

                  // ── Labor ───────────────────────────────────────────────
                  const _SectionLabel('Labor'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Hours stepper
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hours',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _QuantityStepper(
                              value: state.laborHours.toInt(),
                              height: 52,
                              onDecrement: () => ref
                                  .read(newQuoteProvider.notifier)
                                  .setLaborHours(state.laborHours - 1),
                              onIncrement: () => ref
                                  .read(newQuoteProvider.notifier)
                                  .setLaborHours(state.laborHours + 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Rate field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rate (\$/hr)',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 52,
                              child: TextField(
                                controller: _rateController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: GoogleFonts.jetBrainsMono(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (v) {
                                  final rate = double.tryParse(v) ?? 0;
                                  ref
                                      .read(newQuoteProvider.notifier)
                                      .setLaborRate(rate);
                                },
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  prefixStyle: GoogleFonts.jetBrainsMono(
                                    color: Colors.grey.shade400,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1C1F2A),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEC5B13),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Labor total card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEC5B13).withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Labor subtotal',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          fmt.format(state.laborSubtotal),
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Notes ───────────────────────────────────────────────
                  const _SectionLabel('Notes to Client'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    onChanged: (v) =>
                        ref.read(newQuoteProvider.notifier).setNotes(v),
                    decoration: InputDecoration(
                      hintText:
                          'Any special instructions, warranties, or scope details...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1C1F2A),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC5B13),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed summary + preview button (moves with keyboard)
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: _SummaryBottomCard(state: state, onPreview: _onPreview),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Dark Text Field Wrapper ──────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const _DarkField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1C1F2A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEC5B13), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─── Material Row ─────────────────────────────────────────────────────────────

class _MaterialRow extends StatelessWidget {
  final dynamic item; // QuoteItemDraft
  final VoidCallback onToggle;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MaterialRow({
    required this.item,
    required this.onToggle,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isChecked
                    ? const Color(0xFFEC5B13)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isChecked
                      ? const Color(0xFFEC5B13)
                      : Colors.grey.shade600,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: item.isChecked ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmt.format(item.unitPrice)} / unit',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Quantity stepper
          _QuantityStepper(
            value: item.quantity,
            height: 32,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
        ],
      ),
    );
  }
}

// ─── Quantity Stepper ─────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int value;
  final double height;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.value,
    required this.height,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3E),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: onDecrement,
            height: height,
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '$value',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement, height: height),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: height,
        height: height,
        child: Center(
          child: Icon(icon, color: const Color(0xFFEC5B13), size: 16),
        ),
      ),
    );
  }
}

// ─── Summary Bottom Card ──────────────────────────────────────────────────────

class _SummaryBottomCard extends ConsumerWidget {
  final NewQuoteState state;
  final VoidCallback onPreview;

  const _SummaryBottomCard({required this.state, required this.onPreview});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1F2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Subtotals
          _SummaryRow(
            label: 'Materials',
            value: fmt.format(state.materialSubtotal),
            valueColor: Colors.white70,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Labor',
            value: fmt.format(state.laborSubtotal),
            valueColor: Colors.white70,
          ),
          const SizedBox(height: 10),
          // Tax row
          Row(
            children: [
              Text(
                'Tax (${state.taxRate.toStringAsFixed(1)}%)',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const Spacer(),
              Switch(
                value: state.applyTax,
                onChanged: (_) =>
                    ref.read(newQuoteProvider.notifier).toggleTax(),
                thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFEC5B13);
                  }
                  return Colors.grey.shade600;
                }),
                trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFEC5B13).withAlpha(100);
                  }
                  return const Color(0xFF2A2D3E);
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (state.applyTax) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  fmt.format(state.taxAmount),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ],
          const Divider(color: Color(0xFF2A2D3E), height: 20),
          // Total
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESTIMATED TOTAL',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(state.estimatedTotal),
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFEC5B13),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC5B13).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'USD',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFFEC5B13),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Preview button
          GestureDetector(
            onTap: onPreview,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC5B13).withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Preview Quote',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: valueColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
