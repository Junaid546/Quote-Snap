import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../domain/entities/client_entity.dart';
import '../../providers/client_provider.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);

class AddEditClientSheet extends ConsumerStatefulWidget {
  final ClientEntity? client;
  const AddEditClientSheet({super.key, this.client});

  @override
  ConsumerState<AddEditClientSheet> createState() => _AddEditClientSheetState();
}

class _AddEditClientSheetState extends ConsumerState<AddEditClientSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  String? _phoneE164;
  String? _selectedTrade;

  final List<String> _trades = [
    'Plumbing',
    'Electrical',
    'HVAC',
    'Carpentry',
    'Painting',
    'Landscaping',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name);
    _companyController =
        TextEditingController(); // Assuming optional field for now
    _phoneController = TextEditingController(text: widget.client?.phone);
    _phoneE164 = widget.client?.phone;
    _emailController = TextEditingController(text: widget.client?.email);
    _addressController = TextEditingController(text: widget.client?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(clientProvider.notifier);

    if (widget.client == null) {
      // Create new
      final entity = await notifier.addClient(
        name: _nameController.text,
        phone: _phoneE164 ?? _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
      );

      if (entity != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Update existing
      final updated = ClientEntity(
        id: widget.client!.id,
        name: _nameController.text.trim(),
        phone: (_phoneE164 ?? _phoneController.text).trim().isEmpty
            ? null
            : (_phoneE164 ?? _phoneController.text).trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        totalQuotes: widget.client!.totalQuotes,
        totalValue: widget.client!.totalValue,
        createdAt: widget.client!.createdAt,
      );

      final success = await notifier.updateClient(updated);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientError = ref.watch(clientProvider.select((s) => s.error));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
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

            // Title bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.client == null ? 'New Client' : 'Edit Client',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            if (clientError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          clientError,
                          style: GoogleFonts.publicSans(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    _BuildField(
                      controller: _nameController,
                      label: 'Full Name*',
                      hint: 'e.g. Michael Jordan',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _companyController,
                      label: 'Business Name',
                      hint: 'Optional company name',
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHONE NUMBER',
                          style: GoogleFonts.publicSans(
                            color: _kMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IntlPhoneField(
                          controller: _phoneController,
                          initialCountryCode: 'US',
                          disableLengthCheck: true,
                          style: GoogleFonts.publicSans(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          dropdownTextStyle: GoogleFonts.publicSans(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 555-0123',
                            hintStyle: GoogleFonts.publicSans(
                              color: _kMuted,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: _kSurface,
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
                                color: _kOrange,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (phone) {
                            _phoneE164 = phone.number.trim().isEmpty
                                ? null
                                : phone.completeNumber;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'e.g. mike@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _addressController,
                      label: 'Address / Location',
                      hint: 'Job site or billing address',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'TRADE TYPE',
                      style: GoogleFonts.publicSans(
                        color: _kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _trades.map((trade) {
                        final isSelected = _selectedTrade == trade;
                        return ChoiceChip(
                          label: Text(trade),
                          selected: isSelected,
                          onSelected: (val) => setState(
                            () => _selectedTrade = val ? trade : null,
                          ),
                          backgroundColor: _kSurface,
                          selectedColor: _kOrange,
                          labelStyle: GoogleFonts.publicSans(
                            color: isSelected ? Colors.white : _kMuted,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? _kOrange : _kBorder,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 48),

                    // Save Button
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.client == null
                              ? 'Save Client'
                              : 'Update Client',
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

class _BuildField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const _BuildField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.publicSans(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.publicSans(color: _kMuted, fontSize: 14),
            filled: true,
            fillColor: _kSurface,
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
              borderSide: const BorderSide(color: _kOrange, width: 2),
            ),
            errorStyle: GoogleFonts.publicSans(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
