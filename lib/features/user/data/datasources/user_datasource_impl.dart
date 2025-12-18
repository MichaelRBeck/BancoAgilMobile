import '../models/user_profile_model.dart';
import 'firestore_user_profile_datasource.dart';
import 'user_datasource.dart';

class UserDataSourceImpl implements UserDataSource {
  final FirestoreUserProfileDataSource firestore;
  UserDataSourceImpl(this.firestore);

  @override
  Future<UserProfileModel> getProfile({required String uid}) async {
    final data = await firestore.getUserDoc(uid) ?? {};
    return UserProfileModel.fromMap(uid: uid, data: data);
  }

  @override
  Stream<UserProfileModel> observeProfile({required String uid}) {
    return firestore.observeUserDoc(uid).map((data) {
      return UserProfileModel.fromMap(uid: uid, data: data ?? {});
    });
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String cpfDigits,
  }) {
    return firestore.updateUserDoc(uid, {
      'fullName': fullName,
      'cpf': cpfDigits,
      'updatedAt':
          DateTime.now(), // opcional: melhor fazer serverTimestamp no datasource firestore
    });
  }
}
