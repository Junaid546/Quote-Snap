// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/user_profile_entity.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings/edit_business_sheet.dart';
import '../../widgets/settings/subscription_bottom_sheet.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kBorder = Color(0xFF334155);
const _kOrange = Color(0xFFFF6B35);
const _kMuted = Color(0xFF64748B);
const _kRed = Color(0xFFF43F5E);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scrollController = ScrollController();
  final _notificationsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToNotifications() {
    final ctx = _notificationsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/home/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: stateAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _kOrange)),
          error: (err, _) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (state) {
            final profile = state.profile;
            if (profile == null) {
              return const Center(
                child: Text(
                  'Loading profile...',
                  style: TextStyle(color: _kMuted),
                ),
              );
            }
            return Stack(
              children: [
                Column(
                  children: [
                    _SettingsTopBar(
                      onBack: () => _handleBack(context),
                      onBell: _scrollToNotifications,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            _ProfileHeader(profile: profile),
                            const SizedBox(height: 32),
                            _BusinessInfoCard(profile: profile),
                            const SizedBox(height: 32),
                            _EstimateSettingsCard(profile: profile),
                            const SizedBox(height: 32),
                            _NotificationsCard(
                              key: _notificationsKey,
                              state: state,
                            ),
                            const SizedBox(height: 32),
                            _SubscriptionCard(profile: profile),
                            const SizedBox(height: 32),
                            _DataPrivacyCard(),
                            const SizedBox(height: 32),
                            _AboutCard(),
                            const SizedBox(height: 40),
                            _SignOutCard(),
                            const SizedBox(height: 48),
                            _DangerZoneCard(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.isLoading || state.isSaving)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: _kOrange),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _SettingsTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onBell;

  const _SettingsTopBar({required this.onBack, required this.onBell});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                'Settings',
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onBell,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: _kOrange,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────
class _ProfileHeader extends ConsumerWidget {
  final UserProfileEntity profile;
  const _ProfileHeader({required this.profile});

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile != null) {
      await ref
          .read(settingsProvider.notifier)
          .updateLogo(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLogo = profile.logoPath != null && profile.logoPath!.isNotEmpty;
    final initials = profile.businessName.trim().isEmpty
        ? 'BS'
        : profile.businessName
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e.isNotEmpty ? e[0] : '')
              .join()
              .toUpperCase();
    final isPro = profile.subscriptionPlan == 'pro';
    final shortId = profile.id.length >= 8
        ? profile.id.substring(0, 8)
        : profile.id;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasLogo
                    ? null
                    : const LinearGradient(
                        colors: [_kOrange, Color(0xFFD97706)],
                      ),
                image: hasLogo
                    ? DecorationImage(
                        image:
                            (profile.logoPath!.startsWith('http')
                                    ? NetworkImage(profile.logoPath!)
                                    : FileImage(File(profile.logoPath!)))
                                as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: _kBorder, width: 4),
              ),
              child: hasLogo
                  ? null
                  : Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _pickImage(ref),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBg, width: 3),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.businessName,
          style: GoogleFonts.publicSans(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPro ? _kOrange.withValues(alpha: 0.1) : _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPro ? _kOrange.withValues(alpha: 0.5) : _kBorder,
                ),
              ),
              child: Text(
                isPro ? 'Pro Plan \u2713' : 'Free Plan',
                style: GoogleFonts.publicSans(
                  color: isPro ? _kOrange : _kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Account ID: #$shortId',
              style: GoogleFonts.jetBrainsMono(color: _kMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Business Info Card ───────────────────────────────────────────────────────
class _BusinessInfoCard extends StatelessWidget {
  final UserProfileEntity profile;
  const _BusinessInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUSINESS INFORMATION',
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.businessName,
                          style: GoogleFonts.publicSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.ownerName.isEmpty
                              ? 'Owner Info Required'
                              : profile.ownerName,
                          style: GoogleFonts.publicSans(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${profile.email}\n${profile.phone}',
                          style: GoogleFonts.publicSans(
                            color: _kMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => EditBusinessSheet(profile: profile),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange.withValues(alpha: 0.1),
                      foregroundColor: _kOrange,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: _kBorder, height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LICENSE NUMBER',
                    style: GoogleFonts.publicSans(
                      color: _kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profile.licenseNumber.isEmpty
                        ? 'Not Set'
                        : profile.licenseNumber,
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Estimate Settings Card ───────────────────────────────────────────────────
class _EstimateSettingsCard extends ConsumerStatefulWidget {
  final UserProfileEntity profile;
  const _EstimateSettingsCard({required this.profile});

  @override
  ConsumerState<_EstimateSettingsCard> createState() =>
      _EstimateSettingsCardState();
}

class _EstimateSettingsCardState extends ConsumerState<_EstimateSettingsCard> {
  late double _hourlyRate;
  late TextEditingController _taxController;

  @override
  void initState() {
    super.initState();
    _hourlyRate = widget.profile.defaultHourlyRate;
    _taxController = TextEditingController(
      text: widget.profile.defaultTaxRate.toString(),
    );
  }

  @override
  void dispose() {
    _taxController.dispose();
    super.dispose();
  }

  void _onRateChanged(double val) {
    setState(() => _hourlyRate = val);
  }

  void _onRateChangeEnd(double val) {
    ref.read(settingsProvider.notifier).updateDefaultRate(val);
  }

  void _onTaxSave(String val) {
    final r = double.tryParse(val);
    if (r != null) ref.read(settingsProvider.notifier).updateDefaultTaxRate(r);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESTIMATE SETTINGS',
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Hourly Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOURLY RATE',
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Precision adjustment',
                        style: GoogleFonts.publicSans(
                          color: _kMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$${_hourlyRate.toStringAsFixed(0)}/hr',
                      style: GoogleFonts.jetBrainsMono(
                        color: _kOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _kOrange,
                  inactiveTrackColor: _kBg,
                  thumbColor: _kOrange,
                  overlayColor: _kOrange.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _hourlyRate,
                  min: 20,
                  max: 250,
                  divisions: 46, // steps of 5
                  onChanged: _onRateChanged,
                  onChangeEnd: _onRateChangeEnd,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$20 MIN',
                    style: GoogleFonts.jetBrainsMono(
                      color: _kMuted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '\$250 MAX',
                    style: GoogleFonts.jetBrainsMono(
                      color: _kMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Divider(color: _kBorder, height: 32),
              // Default Tax Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEFAULT TAX RATE',
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Global system default',
                        style: GoogleFonts.publicSans(
                          color: _kMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 70,
                    height: 36,
                    child: TextField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onSubmitted: _onTaxSave,
                      style: GoogleFonts.jetBrainsMono(
                        color: _kOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        suffixText: '%',
                        suffixStyle: GoogleFonts.jetBrainsMono(
                          color: _kOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        filled: true,
                        fillColor: _kBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Notifications Card ───────────────────────────────────────────────────────
class _NotificationsCard extends ConsumerWidget {
  final SettingsState state;
  const _NotificationsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTIFICATIONS',
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ToggleRow(
                title: 'Quote Expiry Reminders',
                subtitle: 'Notify 3 days before validity expires',
                value: state.quoteExpiryReminders,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).toggleQuoteExpiry(v),
              ),
              const Divider(color: _kBorder, height: 1),
              _ToggleRow(
                title: 'New Message Alerts',
                subtitle: 'Client queries and approvals',
                value: state.newMessageAlerts,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).toggleNewMessage(v),
              ),
              const Divider(color: _kBorder, height: 1),
              _ToggleRow(
                title: 'Weekly Summary',
                subtitle: 'Monday morning performance digest',
                value: state.weeklySummary,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).toggleWeeklySummary(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.publicSans(color: _kMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kOrange,
            activeTrackColor: _kOrange.withValues(alpha: 0.3),
            inactiveThumbColor: _kMuted,
            inactiveTrackColor: _kBg,
          ),
        ],
      ),
    );
  }
}

// ─── Subscription Card ────────────────────────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final UserProfileEntity profile;
  const _SubscriptionCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isFree = profile.subscriptionPlan == 'free';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUBSCRIPTION',
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kOrange, Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFree ? 'Free Plan' : 'Pro Plan',
                          style: GoogleFonts.publicSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFree ? 'FREE - 5 quotes' : '\$25.00 / MONTHLY',
                          style: GoogleFonts.jetBrainsMono(
                            color: _kOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SubscriptionBottomSheet(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'MANAGE',
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next renewal date',
                    style: GoogleFonts.publicSans(color: _kMuted, fontSize: 13),
                  ),
                  Text(
                    profile.subscriptionRenewal ?? 'N/A',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isFree) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
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
                            'You\'ve used 2/5 free quotes',
                            style: GoogleFonts.publicSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '3 left',
                            style: GoogleFonts.publicSans(
                              color: _kMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.4,
                          minHeight: 6,
                          backgroundColor: _kSurface,
                          color: _kOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const SubscriptionBottomSheet(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Upgrade to Pro',
                            style: GoogleFonts.publicSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Data & Privacy Card ──────────────────────────────────────────────────────
class _DataPrivacyCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATA & PRIVACY',
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.download_rounded,
                title: 'Export All Data',
                color: Colors.blueAccent,
                onTap: () => _exportAllData(context, ref),
              ),
              const Divider(color: _kBorder, height: 1),
              _ActionRow(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear Quote History',
                color: _kOrange,
                onTap: () => _confirmClear(context, ref),
              ),
              const Divider(color: _kBorder, height: 1),
              _ActionRow(
                icon: Icons.privacy_tip_outlined,
                title: AppConstants.privacyPolicyTitle,
                color: _kMuted,
                onTap: () => _showLegalSheet(
                  context,
                  AppConstants.privacyPolicyTitle,
                  AppConstants.privacyPolicyBody,
                ),
              ),
              const Divider(color: _kBorder, height: 1),
              _ActionRow(
                icon: Icons.description_outlined,
                title: AppConstants.termsOfServiceTitle,
                color: _kMuted,
                onTap: () => _showLegalSheet(
                  context,
                  AppConstants.termsOfServiceTitle,
                  AppConstants.termsOfServiceBody,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Clear History?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete all quotes on this device.',
          style: TextStyle(color: _kMuted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear', style: TextStyle(color: _kOrange)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(settingsProvider.notifier).clearQuoteHistory();
    }
  }

  Future<void> _exportAllData(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).exportAllData();
  }

  void _showLegalSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LegalSheet(title: title, body: body),
    );
  }
}

class _LegalSheet extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSheet({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
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
            title,
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Text(
                body,
                style: GoogleFonts.publicSans(
                  color: _kMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── About Card ───────────────────────────────────────────────────────────────
class _AboutCard extends StatefulWidget {
  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'v${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ABOUT',
          style: GoogleFonts.publicSans(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QuoteSnap Version',
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _version,
                      style: GoogleFonts.jetBrainsMono(
                        color: _kMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: _kBorder, height: 1),
              _ActionRow(
                icon: Icons.star_border_rounded,
                title: 'Rate the App',
                color: _kAmber,
                onTap: () => _launchExternal(AppConstants.playStoreUrl),
              ),
              const Divider(color: _kBorder, height: 1),
              _ActionRow(
                icon: Icons.share_rounded,
                title: 'Share App',
                color: Colors.greenAccent,
                onTap: () => Share.share(AppConstants.shareAppText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

const _kAmber = Color(0xFFF59E0B);

// ─── Sign Out & Danger Zone ───────────────────────────────────────────────────
class _SignOutCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: Text(
          'Sign Out',
          style: GoogleFonts.publicSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Sign out of QuoteSnap?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You can sign back in at any time.',
          style: TextStyle(color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (conf == true) ref.read(settingsProvider.notifier).signOut();
  }
}

class _DangerZoneCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DANGER ZONE',
          style: GoogleFonts.publicSans(
            color: _kRed,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kRed.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _kRed, size: 48),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => _showTerminateDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRed,
                    side: const BorderSide(color: _kRed, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'TERMINATE ACCOUNT AUTHORITY',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Once you delete your account, there is no going back. All local and cloud data will be destroyed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  color: _kRed.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTerminateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(
        onConfirm: () async {
          Navigator.pop(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Material(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _kRed),
                    SizedBox(height: 24),
                    Text(
                      'Deleting your data...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
          await ref.read(settingsProvider.notifier).deleteAccount();
          if (context.mounted &&
              Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  const _DeleteAccountDialog({required this.onConfirm});
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  void _validate(String v) {
    setState(() => _canDelete = v == 'DELETE');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kRed, width: 2),
      ),
      title: const Text(
        'Confirm Deletion',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Type DELETE to confirm account termination.',
            style: TextStyle(color: _kMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _validate,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: _kMuted)),
        ),
        ElevatedButton(
          onPressed: _canDelete ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(backgroundColor: _kRed),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
