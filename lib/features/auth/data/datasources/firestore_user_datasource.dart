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
    final ref = users.doc(uid);
    final snap = await ref.get();

    // ✅ se não existe, cria completo
    if (!snap.exists) {
      await ref.set({
        'fullName': fullName,
        'cpf': cpfDigitsOnly,
        'email': emailLower,
        'balance': 0.0,
        'createdAt': fs.FieldValue.serverTimestamp(),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });
      return;
    }

    // ignore: unnecessary_cast
    final data = snap.data() as Map<String, dynamic>? ?? {};
    final patch = <String, dynamic>{};

    if (!data.containsKey('fullName')) patch['fullName'] = fullName;
    if (!data.containsKey('cpf')) patch['cpf'] = cpfDigitsOnly;
    if (!data.containsKey('email')) patch['email'] = emailLower;
    if (!data.containsKey('balance')) patch['balance'] = 0.0;
    if (!data.containsKey('createdAt')) {
      patch['createdAt'] = fs.FieldValue.serverTimestamp();
    }
    patch['updatedAt'] = fs.FieldValue.serverTimestamp();

    if (patch.isNotEmpty) {
      await ref.set(patch, fs.SetOptions(merge: true));
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
