import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreUserProfileDataSource {
  Future<Map<String, dynamic>?> getUserDoc(String uid);
  Stream<Map<String, dynamic>?> observeUserDoc(String uid);
  Future<void> updateUserDoc(String uid, Map<String, dynamic> data);
}

class FirestoreUserProfileDataSourceImpl
    implements FirestoreUserProfileDataSource {
  final FirebaseFirestore firestore;
  FirestoreUserProfileDataSourceImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  @override
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data();
  }

  @override
  Stream<Map<String, dynamic>?> observeUserDoc(String uid) {
    return _users.doc(uid).snapshots().map((s) => s.data());
  }

  @override
  Future<void> updateUserDoc(String uid, Map<String, dynamic> data) {
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }
}
