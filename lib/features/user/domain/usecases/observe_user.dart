import '../entities/app_user.dart';
import '../repositories/user_repository.dart';

class ObserveUser {
  final UserRepository repo;
  ObserveUser(this.repo);

  Stream<AppUser?> call(String uid) => repo.observeUserByUid(uid);
}
