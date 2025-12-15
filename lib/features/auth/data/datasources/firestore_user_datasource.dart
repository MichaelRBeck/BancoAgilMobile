import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class FirestoreUserDataSource {
  final fs.FirebaseFirestore _db;
  FirestoreUserDataSource({fs.FirebaseFirestore? db})
    : _db = db ?? fs.FirebaseFirestore.instance;

  Future<void> createUserDocIfMissing({
    required String uid,
    required String emailLower,
    required String fullName,
    required String cpfDigitsOnly,
  }) async {
    final users = _db.collection('users');
    final doc = await users.doc(uid).get();

    if (!doc.exists) {
      await users.doc(uid).set({
        'fullName': fullName,
        'cpf': cpfDigitsOnly,
        'email': emailLower,
        'balance': 0.0,
        'createdAt': fs.FieldValue.serverTimestamp(),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> upsertCpfIndex({
    required String uid,
    required String fullName,
    required String cpfDigitsOnly,
  }) async {
    await _db.collection('cpfIndex').doc(cpfDigitsOnly).set({
      'uid': uid,
      'fullName': fullName,
      'cpf': cpfDigitsOnly,
      'createdAt': fs.FieldValue.serverTimestamp(),
      'updatedAt': fs.FieldValue.serverTimestamp(),
    }, fs.SetOptions(merge: true));
  }
}
