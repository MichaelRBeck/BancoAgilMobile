import '../repositories/user_repository.dart';

class UpdateUserProfile {
  final UserRepository repo;
  UpdateUserProfile(this.repo);

  Future<void> call({
    required String uid,
    required String fullName,
    required String cpfDigits,
  }) {
    return repo.updateUserProfile(
      uid: uid,
      fullName: fullName,
      cpfDigits: cpfDigits,
    );
  }
}
