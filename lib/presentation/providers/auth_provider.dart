import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/local/database.dart';
import '../../domain/entities/user_profile_entity.dart';
import 'package:drift/drift.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserProfileEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ─── Database Provider ────────────────────────────────────────────────────────

// AppDatabase is now provided by databaseProvider in lib/data/local/database.dart

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final AppDatabase _db;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthNotifier(this._authRepo, this._db) : super(const AuthLoading()) {
    _init();
  }

  void _init() {
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user == null) {
        state = const AuthUnauthenticated();
      } else {
        try {
          final profile = await _authRepo.getCurrentUser();
          if (profile != null) {
            state = AuthAuthenticated(profile);
          } else {
            state = const AuthUnauthenticated();
          }
        } catch (_) {
          state = const AuthUnauthenticated();
        }
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthLoading();
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // authStateChanges listener will pick up success
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (_) {
      state = const AuthError(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> signUpWithEmail(
    String name,
    String businessName,
    String email,
    String password,
  ) async {
    state = const AuthLoading();
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      final profile = UserProfileEntity(
        id: user.uid,
        businessName: businessName.trim(),
        ownerName: name.trim(),
        email: email.trim(),
        phone: '',
        licenseNumber: '',
        defaultHourlyRate: 85.0,
        defaultTaxRate: 8.5,
        subscriptionPlan: 'free',
      );

      // Save to Firestore
      await _authRepo.updateUserProfile(profile);

      // Save to local SQLite
      await _saveProfileToSQLite(profile);

      state = AuthAuthenticated(profile);
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (_) {
      state = const AuthError('Sign-up failed. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final profile = await _authRepo.signInWithGoogle();
      if (profile != null) {
        await _saveProfileToSQLite(profile);
        state = AuthAuthenticated(profile);
      } else {
        state = const AuthUnauthenticated();
      }
    } on FirebaseAuthException catch (e) {
      state = AuthError(_mapFirebaseError(e.code));
    } catch (_) {
      state = const AuthError('Google sign-in failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    state = const AuthUnauthenticated();
  }

  Future<void> _saveProfileToSQLite(UserProfileEntity profile) async {
    try {
      await _db
          .into(_db.userProfile)
          .insertOnConflictUpdate(
            UserProfileCompanion.insert(
              id: profile.id,
              businessName: profile.businessName,
              ownerName: profile.ownerName,
              email: profile.email,
              phone: profile.phone,
              licenseNumber: profile.licenseNumber,
              logoPath: Value(profile.logoPath),
              defaultHourlyRate: Value(profile.defaultHourlyRate),
              defaultTaxRate: Value(profile.defaultTaxRate),
              subscriptionPlan: Value(profile.subscriptionPlan),
              subscriptionRenewal: Value(profile.subscriptionRenewal),
            ),
          );
    } catch (_) {
      // Non-critical: Firestore has the source of truth
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Check your email and password.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final db = ref.read(databaseProvider);
  return AuthNotifier(repo, db);
});

// Stream for GoRouter redirect
final authStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
