import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../models/user_profile_model.dart';
import 'user_datasource.dart';

class UserFirestoreDataSource implements UserDataSource {
  final fs.FirebaseFirestore firestore;
  UserFirestoreDataSource(this.firestore);

  fs.CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users');

  @override
  Future<UserProfileModel> getProfile({required String uid}) async {
    final doc = await _col.doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    return UserProfileModel.fromMap(uid: uid, data: data);
  }

  @override
  Stream<UserProfileModel> observeProfile({required String uid}) {
    return _col.doc(uid).snapshots().map((snap) {
      final data = snap.data() ?? <String, dynamic>{};
      return UserProfileModel.fromMap(uid: uid, data: data);
    });
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String cpfDigits,
  }) async {
    await _col.doc(uid).set({
      'fullName': fullName,
      'cpf': cpfDigits,
      'updatedAt': fs.FieldValue.serverTimestamp(),
    }, fs.SetOptions(merge: true));
  }
}
