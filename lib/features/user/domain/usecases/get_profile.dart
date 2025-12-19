import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class GetProfile {
  final UserRepository repo;
  GetProfile(this.repo);

  Future<UserProfile> call({required String uid}) {
    return repo.getProfile(uid: uid);
  }
}
