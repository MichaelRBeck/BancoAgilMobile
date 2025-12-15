import '../entities/app_user.dart';

abstract class UserRepository {
  Future<AppUser?> getUserByUid(String uid);
  Stream<AppUser?> observeUserByUid(String uid);
  Future<void> updateUserProfile(String uid, {String? name, String? cpf});
}
