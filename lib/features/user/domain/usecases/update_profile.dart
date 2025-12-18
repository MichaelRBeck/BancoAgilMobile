import '../repositories/user_repository.dart';

class UpdateProfile {
  final UserRepository repo;
  UpdateProfile(this.repo);

  Future<void> call({
    required String uid,
    required String fullName,
    required String cpfDigits,
  }) {
    return repo.updateProfile(
      uid: uid,
      fullName: fullName,
      cpfDigits: cpfDigits,
    );
  }
}
