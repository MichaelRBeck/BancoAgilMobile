import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class GetUser {
  final UserRepository repo;
  GetUser(this.repo);

  Future<UserProfile> call({required String uid}) {
    return repo.getProfile(uid: uid);
  }
}
