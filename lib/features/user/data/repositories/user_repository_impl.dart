import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/firestore_user_profile_datasource.dart';
import '../models/app_user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirestoreUserProfileDataSource ds;
  UserRepositoryImpl({required this.ds});

  @override
  Future<AppUser?> getUserByUid(String uid) async {
    final data = await ds.getUserDoc(uid);
    if (data == null) return null;
    return AppUserModel.fromMap(uid, data);
  }

  @override
  Stream<AppUser?> observeUserByUid(String uid) {
    return ds.observeUserDoc(uid).map((data) {
      if (data == null) return null;
      return AppUserModel.fromMap(uid, data);
    });
  }

  @override
  Future<void> updateUserProfile(String uid, {String? name, String? cpf}) {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (cpf != null) payload['cpf'] = cpf;
    return ds.updateUserDoc(uid, payload);
  }
}
