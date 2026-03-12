import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quote_snap/core/theme/app_theme.dart';
import 'package:quote_snap/core/router/app_router.dart';
import 'package:quote_snap/data/services/sync_service.dart';
import 'package:quote_snap/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FirebaseApp? app;
    if (Firebase.apps.isNotEmpty) {
      app = Firebase.app();
    } else {
      try {
        app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          app = Firebase.app();
        } else {
          rethrow;
        }
      }
    }

    // Enable Offline Persistence for Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // ── Crashlytics Setup ──────────────────────────────────────────────────────
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );

    // Forward Flutter framework errors to Crashlytics
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Forward async errors on the Dart isolate to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const ProviderScope(child: QuoteSnapApp()));
}

class QuoteSnapApp extends ConsumerWidget {
  const QuoteSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize global background sync service
    ref.watch(syncServiceProvider);

    return MaterialApp.router(
      title: 'QuoteSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

