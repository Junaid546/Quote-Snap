import '../entities/user_profile_entity.dart';

abstract class IAuthRepository {
  Future<UserProfileEntity?> signInWithGoogle();
  Future<void> signOut();
  Future<UserProfileEntity?> getCurrentUser();
  Stream<UserProfileEntity?> authStateChanges();
  Future<void> updateUserProfile(UserProfileEntity profile);
}
