import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource ds;
  UserRepositoryImpl(this.ds);

  @override
  Future<UserProfile> getProfile({required String uid}) async {
    final m = await ds.getProfile(uid: uid);
    return m.toEntity();
  }

  @override
  Stream<UserProfile> observeProfile({required String uid}) {
    return ds.observeProfile(uid: uid).map((m) => m.toEntity());
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String cpfDigits,
  }) {
    return ds.updateProfile(uid: uid, fullName: fullName, cpfDigits: cpfDigits);
  }
}
