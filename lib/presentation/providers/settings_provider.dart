import 'dart:async';
// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'auth_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class SettingsState {
  final UserProfileEntity? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool hasUnsavedChanges;

  // Notification Toggles
  final bool quoteExpiryReminders;
  final bool newMessageAlerts;
  final bool weeklySummary;

  const SettingsState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.hasUnsavedChanges = false,
    this.quoteExpiryReminders = true,
    this.newMessageAlerts = true,
    this.weeklySummary = false,
  });

  SettingsState copyWith({
    UserProfileEntity? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? hasUnsavedChanges,
    bool? quoteExpiryReminders,
    bool? newMessageAlerts,
    bool? weeklySummary,
    bool clearError = false,
  }) {
    return SettingsState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      quoteExpiryReminders: quoteExpiryReminders ?? this.quoteExpiryReminders,
      newMessageAlerts: newMessageAlerts ?? this.newMessageAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  late AppDatabase _db;
  late IAuthRepository _authRepo;
  late SharedPreferences _prefs;
  late NotificationService _notificationService;

  @override
  Future<SettingsState> build() async {
    _db = ref.watch(databaseProvider);
    _authRepo = ref.watch(authRepositoryProvider);
    _notificationService = ref.watch(notificationServiceProvider);
    _prefs = await SharedPreferences.getInstance();

    final profile = await _fetchProfile();

    return SettingsState(
      profile: profile,
      quoteExpiryReminders: _prefs.getBool('quoteExpiryReminders') ?? true,
      newMessageAlerts: _prefs.getBool('newMessageAlerts') ?? true,
      weeklySummary: _prefs.getBool('weeklySummary') ?? false,
    );
  }

  // ─── Profile Loading ────────────────────────────────────────────────────────
  Future<UserProfileEntity?> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    UserProfileEntity? localProfile;
    try {
      final result = await (_db.select(
        _db.userProfile,
      )..where((t) => t.id.equals(user.uid))).getSingleOrNull();

      if (result != null) {
        localProfile = UserProfileEntity(
          id: result.id,
          businessName: result.businessName,
          ownerName: result.ownerName,
          email: result.email,
          phone: result.phone,
          licenseNumber: result.licenseNumber,
          logoPath: result.logoPath,
          defaultHourlyRate: result.defaultHourlyRate,
          defaultTaxRate: result.defaultTaxRate,
          subscriptionPlan: result.subscriptionPlan,
          subscriptionRenewal: result.subscriptionRenewal,
        );
      }
    } catch (_) {
      localProfile = null;
    }

    if (localProfile != null) return localProfile;

    // Fallback to auth repo if not in sqlite yet
    try {
      final remoteProfile = await _authRepo
          .getCurrentUser()
          .timeout(const Duration(seconds: 5));
      if (remoteProfile != null) {
        // Save to SQLite
        await _db
            .into(_db.userProfile)
            .insert(
              UserProfileCompanion.insert(
                id: remoteProfile.id,
                businessName: remoteProfile.businessName,
                ownerName: remoteProfile.ownerName,
                email: remoteProfile.email,
                phone: remoteProfile.phone,
                licenseNumber: remoteProfile.licenseNumber,
                logoPath: Value(remoteProfile.logoPath),
                defaultHourlyRate: Value(remoteProfile.defaultHourlyRate),
                defaultTaxRate: Value(remoteProfile.defaultTaxRate),
                subscriptionPlan: Value(remoteProfile.subscriptionPlan),
                subscriptionRenewal: Value(remoteProfile.subscriptionRenewal),
              ),
              mode: InsertMode.insertOrReplace,
            );
        return remoteProfile;
      }
    } catch (_) {
      // Ignore and fall back to a minimal local profile.
    }

    return _fallbackProfileFromAuth(user);
  }

  UserProfileEntity _fallbackProfileFromAuth(User user) {
    return UserProfileEntity(
      id: user.uid,
      businessName: '',
      ownerName: user.displayName ?? '',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      licenseNumber: '',
      defaultHourlyRate: 85.0,
      defaultTaxRate: 8.5,
      subscriptionPlan: 'free',
    );
  }

  Future<void> loadProfile() async {
    state = const AsyncLoading();
    final profile = await _fetchProfile();
    if (profile != null) {
      state = AsyncData(
        state.valueOrNull?.copyWith(profile: profile) ??
            SettingsState(profile: profile),
      );
    }
  }

  // ─── Business Info Update ───────────────────────────────────────────────────
  Future<void> updateBusinessInfo({
    required String businessName,
    required String ownerName,
    required String phone,
    required String email,
    required String licenseNumber,
  }) async {
    final curr = state.valueOrNull?.profile;
    if (curr == null) return;

    state = AsyncData(state.value!.copyWith(isSaving: true));

    try {
      final updated = UserProfileEntity(
        id: curr.id,
        businessName: businessName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        licenseNumber: licenseNumber,
        logoPath: curr.logoPath,
        defaultHourlyRate: curr.defaultHourlyRate,
        defaultTaxRate: curr.defaultTaxRate,
        subscriptionPlan: curr.subscriptionPlan,
        subscriptionRenewal: curr.subscriptionRenewal,
      );

      // 1. Update SQLite
      await (_db.update(
        _db.userProfile,
      )..where((t) => t.id.equals(curr.id))).write(
        UserProfileCompanion(
          businessName: Value(businessName),
          ownerName: Value(ownerName),
          email: Value(email),
          phone: Value(phone),
          licenseNumber: Value(licenseNumber),
        ),
      );

      // 2. Auth update
      await FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(email)
          .catchError((_) {});
      await FirebaseAuth.instance.currentUser?.updateDisplayName(ownerName);

      // 3. Firestore async
      _authRepo.updateUserProfile(updated);

      state = AsyncData(
        state.value!.copyWith(
          profile: updated,
          isSaving: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isSaving: false, error: e.toString()),
      );
    }
  }

  // ─── Logo Update ────────────────────────────────────────────────────────────
  Future<void> updateLogo(File imageFile) async {
    final curr = state.valueOrNull?.profile;
    if (curr == null) return;

    state = AsyncData(state.value!.copyWith(isSaving: true));

    try {
      // 1. Save locally
      final appDir = await getApplicationDocumentsDirectory();
      final ext = imageFile.path.split('.').last;
      final localPath = '${appDir.path}/logo_${curr.id}.$ext';
      final savedImage = await imageFile.copy(localPath);

      // 2. Update SQLite
      await (_db.update(_db.userProfile)..where((t) => t.id.equals(curr.id)))
          .write(UserProfileCompanion(logoPath: Value(savedImage.path)));

      final updatedLocal = UserProfileEntity(
        id: curr.id,
        businessName: curr.businessName,
        ownerName: curr.ownerName,
        email: curr.email,
        phone: curr.phone,
        licenseNumber: curr.licenseNumber,
        logoPath: savedImage.path,
        defaultHourlyRate: curr.defaultHourlyRate,
        defaultTaxRate: curr.defaultTaxRate,
        subscriptionPlan: curr.subscriptionPlan,
        subscriptionRenewal: curr.subscriptionRenewal,
      );
      state = AsyncData(
        state.value!.copyWith(profile: updatedLocal, isSaving: false),
      );

      // 3. Upload async
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/${curr.id}/logo.jpg',
      );
      await storageRef.putFile(savedImage);
      final downloadUrl = await storageRef.getDownloadURL();

      // 4. Update Firestore
      final updatedRemote = UserProfileEntity(
        id: curr.id,
        businessName: curr.businessName,
        ownerName: curr.ownerName,
        email: curr.email,
        phone: curr.phone,
        licenseNumber: curr.licenseNumber,
        logoPath: downloadUrl,
        defaultHourlyRate: curr.defaultHourlyRate,
        defaultTaxRate: curr.defaultTaxRate,
        subscriptionPlan: curr.subscriptionPlan,
        subscriptionRenewal: curr.subscriptionRenewal,
      );
      await _authRepo.updateUserProfile(updatedRemote);
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isSaving: false, error: e.toString()),
      );
    }
  }

  // ─── Estimate Settings ───────────────────────────────────────────────────────
  Future<void> updateDefaultRate(double rate) async {
    final curr = state.valueOrNull?.profile;
    if (curr == null) return;

    await (_db.update(_db.userProfile)..where((t) => t.id.equals(curr.id)))
        .write(UserProfileCompanion(defaultHourlyRate: Value(rate)));

    final updated = UserProfileEntity(
      id: curr.id,
      businessName: curr.businessName,
      ownerName: curr.ownerName,
      email: curr.email,
      phone: curr.phone,
      licenseNumber: curr.licenseNumber,
      logoPath: curr.logoPath,
      defaultHourlyRate: rate,
      defaultTaxRate: curr.defaultTaxRate,
      subscriptionPlan: curr.subscriptionPlan,
      subscriptionRenewal: curr.subscriptionRenewal,
    );

    state = AsyncData(state.value!.copyWith(profile: updated));
    _authRepo.updateUserProfile(updated);
  }

  Future<void> updateDefaultTaxRate(double rate) async {
    final curr = state.valueOrNull?.profile;
    if (curr == null) return;

    await (_db.update(_db.userProfile)..where((t) => t.id.equals(curr.id)))
        .write(UserProfileCompanion(defaultTaxRate: Value(rate)));

    final updated = UserProfileEntity(
      id: curr.id,
      businessName: curr.businessName,
      ownerName: curr.ownerName,
      email: curr.email,
      phone: curr.phone,
      licenseNumber: curr.licenseNumber,
      logoPath: curr.logoPath,
      defaultHourlyRate: curr.defaultHourlyRate,
      defaultTaxRate: rate,
      subscriptionPlan: curr.subscriptionPlan,
      subscriptionRenewal: curr.subscriptionRenewal,
    );

    state = AsyncData(state.value!.copyWith(profile: updated));
    _authRepo.updateUserProfile(updated);
  }

  // ─── Subscription ────────────────────────────────────────────────────────────
  Future<void> updateSubscriptionPlan(String plan) async {
    final curr = state.valueOrNull?.profile;
    if (curr == null) return;

    await (_db.update(_db.userProfile)..where((t) => t.id.equals(curr.id)))
        .write(UserProfileCompanion(subscriptionPlan: Value(plan)));
    final updated = UserProfileEntity(
      id: curr.id,
      businessName: curr.businessName,
      ownerName: curr.ownerName,
      email: curr.email,
      phone: curr.phone,
      licenseNumber: curr.licenseNumber,
      logoPath: curr.logoPath,
      defaultHourlyRate: curr.defaultHourlyRate,
      defaultTaxRate: curr.defaultTaxRate,
      subscriptionPlan: plan,
      subscriptionRenewal: curr.subscriptionRenewal,
    );

    state = AsyncData(state.value!.copyWith(profile: updated));
    _authRepo.updateUserProfile(updated);
  }

  // ─── Notifications ───────────────────────────────────────────────────────────
  Future<void> toggleQuoteExpiry(bool value) async {
    await _prefs.setBool('quoteExpiryReminders', value);
    state = AsyncData(state.value!.copyWith(quoteExpiryReminders: value));
  }

  Future<void> toggleNewMessage(bool value) async {
    await _prefs.setBool('newMessageAlerts', value);
    state = AsyncData(state.value!.copyWith(newMessageAlerts: value));
  }

  Future<void> toggleWeeklySummary(bool value) async {
    await _prefs.setBool('weeklySummary', value);
    state = AsyncData(state.value!.copyWith(weeklySummary: value));

    try {
      await _notificationService.initialize();
      if (value) {
        await _notificationService.scheduleWeeklySummary();
      } else {
        await _notificationService.cancelWeeklySummary();
      }
    } catch (_) {
      // Ignore notification scheduling errors to avoid blocking UI toggles.
    }
  }

  // ─── Data & Privacy ──────────────────────────────────────────────────────────
  Future<void> exportAllData() async {
    try {
      final quotes = await _db.select(_db.quotes).get();
      final quoteItems = await _db.select(_db.quoteItems).get();
      final clients = await _db.select(_db.clients).get();

      final quoteRows = <List<dynamic>>[
        [
          'Quote Number',
          'Client',
          'Job Type',
          'Date',
          'Amount',
          'Status',
        ],
        for (final q in quotes)
          [
            q.quoteNumber,
            q.clientName,
            q.jobType,
            q.createdAt,
            q.totalAmount,
            q.status,
          ],
      ];

      final itemRows = <List<dynamic>>[
        ['Quote Id', 'Item Name', 'Unit Price', 'Quantity', 'Checked'],
        for (final item in quoteItems)
          [
            item.quoteId,
            item.name,
            item.unitPrice,
            item.quantity,
            item.isChecked,
          ],
      ];

      final clientRows = <List<dynamic>>[
        [
          'Client Name',
          'Phone',
          'Email',
          'Address',
          'Total Quotes',
          'Total Value',
        ],
        for (final c in clients)
          [
            c.name,
            c.phone ?? '',
            c.email ?? '',
            c.address ?? '',
            c.totalQuotes,
            c.totalValue,
          ],
      ];

      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final quotePath = '${dir.path}/quotes_$ts.csv';
      final itemPath = '${dir.path}/quote_items_$ts.csv';
      final clientPath = '${dir.path}/clients_$ts.csv';

      await File(quotePath).writeAsString(_buildCsv(quoteRows));
      await File(itemPath).writeAsString(_buildCsv(itemRows));
      await File(clientPath).writeAsString(_buildCsv(clientRows));

      await Share.shareXFiles(
        [XFile(quotePath), XFile(itemPath), XFile(clientPath)],
        text: 'QuoteSnap Export Data',
      );
    } catch (e) {
      state = AsyncData(state.value!.copyWith(error: 'Failed to export: $e'));
    }
  }

  String _buildCsv(List<List<dynamic>> rows) {
    return rows
        .map(
          (r) => r
              .map((c) => '"${c.toString().replaceAll('"', '""')}"')
              .join(','),
        )
        .join('\n');
  }

  Future<void> clearQuoteHistory() async {
    await _db.delete(_db.quotes).go();
    await _db.delete(_db.quoteItems).go();
    // Clients stats might be reset here
  }

  // ─── Account Controls ────────────────────────────────────────────────────────
  Future<void> signOut() async {
    state = AsyncData(state.value!.copyWith(isLoading: true));
    try {
      await _authRepo.signOut();

      // Preserve onboarding flag
      final onboardingDone = _prefs.getBool('onboarding_done');
      await _prefs.clear();
      if (onboardingDone != null) {
        await _prefs.setBool('onboarding_done', onboardingDone);
      }
      // Auth changes are handled reactively by AuthNotifier.
    } finally {
      state = AsyncData(state.value!.copyWith(isLoading: false));
    }
  }

  Future<void> deleteAccount() async {
    final curr = state.valueOrNull?.profile;
    if (curr == null) return;

    state = AsyncData(state.value!.copyWith(isLoading: true));

    try {
      // 1. Delete SQLite
      await _db.delete(_db.quotes).go();
      await _db.delete(_db.quoteItems).go();
      await _db.delete(_db.clients).go();
      await _db.delete(_db.userProfile).go();

      // 2. Delete Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(curr.id)
          .delete();
      // Need a cloud function to delete subcollections optimally, or do it manually

      // 3. Delete Auth Account
      await FirebaseAuth.instance.currentUser?.delete();
      await _authRepo.signOut();

      // 4. Clear Prefs
      await _prefs.clear();
      // Auth changes are handled reactively by AuthNotifier.
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  void clearError() =>
      state = AsyncData(state.value!.copyWith(clearError: true));
}

/// The main provider
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  () => SettingsNotifier(),
);
