import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/user_profile_entity.dart';
import '../../providers/settings_provider.dart';

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);

class EditBusinessSheet extends ConsumerStatefulWidget {
  final UserProfileEntity profile;
  const EditBusinessSheet({super.key, required this.profile});

  @override
  ConsumerState<EditBusinessSheet> createState() => _EditBusinessSheetState();
}

class _EditBusinessSheetState extends ConsumerState<EditBusinessSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessController;
  late final TextEditingController _ownerController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _licenseController;

  @override
  void initState() {
    super.initState();
    _businessController = TextEditingController(
      text: widget.profile.businessName,
    );
    _ownerController = TextEditingController(text: widget.profile.ownerName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _emailController = TextEditingController(text: widget.profile.email);
    _licenseController = TextEditingController(
      text: widget.profile.licenseNumber,
    );
  }

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(settingsProvider.notifier)
        .updateBusinessInfo(
          businessName: _businessController.text.trim(),
          ownerName: _ownerController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          licenseNumber: _licenseController.text.trim(),
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                    'Edit Business Info',
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
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  children: [
                    _BuildField(
                      controller: _businessController,
                      label: 'Business Name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _ownerController,
                      label: 'Owner Name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.contains('@') ? null : 'Invalid email',
                    ),
                    const SizedBox(height: 20),
                    _BuildField(
                      controller: _licenseController,
                      label: 'License Number',
                      hint: 'Optional',
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.publicSans(
                            color: Colors.white,
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
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _BuildField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
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
          ),
        ),
      ],
    );
  }
}
