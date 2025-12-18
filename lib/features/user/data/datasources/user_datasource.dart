import '../models/user_profile_model.dart';

abstract class UserDataSource {
  Future<UserProfileModel> getProfile({required String uid});
  Stream<UserProfileModel> observeProfile({required String uid});
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String cpfDigits,
  });
}
