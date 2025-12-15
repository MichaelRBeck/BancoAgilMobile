import '../repositories/user_repository.dart';

class UpdateUserProfile {
  final UserRepository repo;
  UpdateUserProfile(this.repo);

  Future<void> call(String uid, {String? name, String? cpf}) {
    return repo.updateUserProfile(uid, name: name, cpf: cpf);
  }
}
