import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class ObserveUser {
  final UserRepository repo;
  ObserveUser(this.repo);

  Stream<UserProfile> call({required String uid}) async* {
    final profile = await repo.getProfile(uid: uid);
    yield profile;
  }
}
