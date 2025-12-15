import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

class GetUser {
  final UserRepository repo;
  GetUser(this.repo);

  Future<AppUser?> call(String uid) => repo.getUserByUid(uid);
}
