import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';

// ─── Subscription Plan ───────────────────────────────────────────────────────

enum SubscriptionPlan { free, pro, team }

extension SubscriptionPlanX on SubscriptionPlan {
  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.team:
        return 'Team';
    }
  }

  int get quoteLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return 5;
      case SubscriptionPlan.pro:
        return -1; // unlimited
      case SubscriptionPlan.team:
        return -1; // unlimited
    }
  }

  bool get isUnlimited => this != SubscriptionPlan.free;
}

// ─── Subscription State ──────────────────────────────────────────────────────

class SubscriptionState {
  final SubscriptionPlan currentPlan;
  final int quotesUsed;
  final int quotesLimit;
  final bool canCreateQuote;
  final DateTime? renewalDate;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.currentPlan = SubscriptionPlan.free,
    this.quotesUsed = 0,
    this.quotesLimit = 5,
    this.canCreateQuote = true,
    this.renewalDate,
    this.isLoading = false,
    this.error,
  });

  double get usagePercentage {
    if (currentPlan.isUnlimited) return 0.0;
    return (quotesUsed / quotesLimit).clamp(0.0, 1.0);
  }

  bool get isAtLimit => !canCreateQuote && currentPlan == SubscriptionPlan.free;
  bool get isPro => currentPlan == SubscriptionPlan.pro;
  bool get isFree => currentPlan == SubscriptionPlan.free;

  SubscriptionState copyWith({
    SubscriptionPlan? currentPlan,
    int? quotesUsed,
    int? quotesLimit,
    bool? canCreateQuote,
    DateTime? renewalDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SubscriptionState(
      currentPlan: currentPlan ?? this.currentPlan,
      quotesUsed: quotesUsed ?? this.quotesUsed,
      quotesLimit: quotesLimit ?? this.quotesLimit,
      canCreateQuote: canCreateQuote ?? this.canCreateQuote,
      renewalDate: renewalDate ?? this.renewalDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  late AppDatabase _db;
  late SharedPreferences _prefs;

  @override
  Future<SubscriptionState> build() async {
    _db = ref.watch(databaseProvider);
    _prefs = await SharedPreferences.getInstance();
    return _load();
  }

  Future<SubscriptionState> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SubscriptionState();

    // Read profile from local SQLite
    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.id.equals(user.uid))).getSingleOrNull();

    final planStr = row?.subscriptionPlan ?? 'free';
    final plan = _parsePlan(planStr);

    // Count quotes used this month
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final allQuotes = await (_db.select(
      _db.quotes,
    )..where((t) => t.createdAt.isBiggerOrEqualValue(monthStart))).get();
    final quotesUsed = allQuotes.length;

    // Renewal date from SharedPreferences
    final renewalTs = _prefs.getInt('renewalDate');
    final renewalDate = renewalTs != null
        ? DateTime.fromMillisecondsSinceEpoch(renewalTs)
        : null;

    final canCreate = plan.isUnlimited || quotesUsed < plan.quoteLimit;

    return SubscriptionState(
      currentPlan: plan,
      quotesUsed: quotesUsed,
      quotesLimit: plan.quoteLimit > 0 ? plan.quoteLimit : 9999,
      canCreateQuote: canCreate,
      renewalDate: renewalDate,
    );
  }

  Future<void> loadSubscription() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  // ─── Quota Check ────────────────────────────────────────────────────────────
  Future<bool> checkQuoteLimit() async {
    final curr = state.valueOrNull;
    if (curr == null) return false;

    if (curr.currentPlan.isUnlimited) return true;

    // Recount from DB to be safe
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final count = await (_db.select(
      _db.quotes,
    )..where((t) => t.createdAt.isBiggerOrEqualValue(monthStart))).get();

    final allowed = count.length < curr.currentPlan.quoteLimit;

    // Update state
    state = AsyncData(
      curr.copyWith(quotesUsed: count.length, canCreateQuote: allowed),
    );

    return allowed;
  }

  // ─── Upgrade to Pro ─────────────────────────────────────────────────────────
  Future<void> upgradeToPro() async {
    // TODO: Replace with RevenueCat/Stripe integration in production
    // See: https://www.revenuecat.com/ or https://stripe.com/
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = AsyncData(state.value!.copyWith(isLoading: true));

    try {
      final renewal = DateTime.now().add(const Duration(days: 30));

      // 1. Update SQLite
      await (_db.update(_db.userProfile)..where((t) => t.id.equals(user.uid)))
          .write(const UserProfileCompanion(subscriptionPlan: Value('pro')));

      // 2. Save renewal date to SharedPreferences
      await _prefs.setInt('renewalDate', renewal.millisecondsSinceEpoch);

      // 3. Sync to Firestore async (fire and forget)
      _syncPlanToFirestore(user.uid, 'pro', renewal);

      state = AsyncData(
        state.value!.copyWith(
          currentPlan: SubscriptionPlan.pro,
          quotesLimit: 9999,
          canCreateQuote: true,
          renewalDate: renewal,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  Future<void> upgradeToTeam() async {
    // TODO: Replace with RevenueCat/Stripe integration in production
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = AsyncData(state.value!.copyWith(isLoading: true));

    try {
      final renewal = DateTime.now().add(const Duration(days: 30));
      await (_db.update(_db.userProfile)..where((t) => t.id.equals(user.uid)))
          .write(const UserProfileCompanion(subscriptionPlan: Value('team')));
      await _prefs.setInt('renewalDate', renewal.millisecondsSinceEpoch);
      _syncPlanToFirestore(user.uid, 'team', renewal);

      state = AsyncData(
        state.value!.copyWith(
          currentPlan: SubscriptionPlan.team,
          quotesLimit: 9999,
          canCreateQuote: true,
          renewalDate: renewal,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  Future<void> downgradeToFree() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await (_db.update(_db.userProfile)..where((t) => t.id.equals(user.uid)))
        .write(const UserProfileCompanion(subscriptionPlan: Value('free')));
    await _prefs.remove('renewalDate');
    _syncPlanToFirestore(user.uid, 'free', null);

    // Recount to recalculate canCreate
    final loaded = await _load();
    state = AsyncData(loaded);
  }

  Future<void> simulatePayment(String plan) async {
    // Simulates 2-second processing delay before upgrading
    await Future.delayed(const Duration(seconds: 2));
    if (plan == 'pro') {
      await upgradeToPro();
    } else if (plan == 'team') {
      await upgradeToTeam();
    }
  }

  void _syncPlanToFirestore(String uid, String plan, DateTime? renewal) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
          'subscriptionPlan': plan,
          'subscriptionRenewal': renewal?.toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((_) {});
  }

  static SubscriptionPlan _parsePlan(String s) {
    switch (s.toLowerCase()) {
      case 'pro':
        return SubscriptionPlan.pro;
      case 'team':
        return SubscriptionPlan.team;
      default:
        return SubscriptionPlan.free;
    }
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      () => SubscriptionNotifier(),
    );
