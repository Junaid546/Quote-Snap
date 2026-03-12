import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserProfileEntity?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    final user = userCredential.user;
    if (user != null) {
      return await _fetchOrCreateUserProfile(user);
    }
    return null;
  }

  Future<UserProfileEntity> _fetchOrCreateUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final data = docSnap.data()!;
      return UserProfileEntity(
        id: user.uid,
        businessName: data['businessName'] ?? '',
        ownerName: data['ownerName'] ?? user.displayName ?? '',
        email: data['email'] ?? user.email ?? '',
        phone: data['phone'] ?? user.phoneNumber ?? '',
        licenseNumber: data['licenseNumber'] ?? '',
        logoPath: data['logoPath'],
        defaultHourlyRate:
            (data['defaultHourlyRate'] as num?)?.toDouble() ?? 85.0,
        defaultTaxRate: (data['defaultTaxRate'] as num?)?.toDouble() ?? 8.5,
        subscriptionPlan: data['subscriptionPlan'] ?? 'free',
        subscriptionRenewal: data['subscriptionRenewal'],
      );
    } else {
      final newProfile = UserProfileEntity(
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
      await docRef.set({
        'businessName': newProfile.businessName,
        'ownerName': newProfile.ownerName,
        'email': newProfile.email,
        'phone': newProfile.phone,
        'licenseNumber': newProfile.licenseNumber,
        'logoPath': newProfile.logoPath,
        'defaultHourlyRate': newProfile.defaultHourlyRate,
        'defaultTaxRate': newProfile.defaultTaxRate,
        'subscriptionPlan': newProfile.subscriptionPlan,
        'subscriptionRenewal': newProfile.subscriptionRenewal,
      });
      return newProfile;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<UserProfileEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _fetchOrCreateUserProfile(user);
    }
    return null;
  }

  @override
  Stream<UserProfileEntity?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        return await _fetchOrCreateUserProfile(user);
      }
      return null;
    });
  }

  @override
  Future<void> updateUserProfile(UserProfileEntity profile) async {
    final docRef = _firestore.collection('users').doc(profile.id);
    await docRef.set({
      'businessName': profile.businessName,
      'ownerName': profile.ownerName,
      'email': profile.email,
      'phone': profile.phone,
      'licenseNumber': profile.licenseNumber,
      'logoPath': profile.logoPath,
      'defaultHourlyRate': profile.defaultHourlyRate,
      'defaultTaxRate': profile.defaultTaxRate,
      'subscriptionPlan': profile.subscriptionPlan,
      'subscriptionRenewal': profile.subscriptionRenewal,
    }, SetOptions(merge: true));
  }
}
