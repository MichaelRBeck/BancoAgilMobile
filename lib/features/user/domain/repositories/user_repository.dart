import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getProfile({required String uid});
  Stream<UserProfile> observeProfile({required String uid});

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String cpfDigits,
  });
}
