import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class ObserveProfile {
  final UserRepository repo;
  ObserveProfile(this.repo);

  Stream<UserProfile> call({required String uid}) {
    return repo.observeProfile(uid: uid);
  }
}
