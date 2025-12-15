import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/cpf_validator.dart';

abstract class UserProfileDataSource {
  Future<Map<String, dynamic>?> getProfileByUid(String uid);

  /// Cria/atualiza o perfil do usuário (uid vem de fora)
  /// e garante unicidade do CPF via cpfIndex/{cpf}
  Future<void> upsertProfile({
    required String uid,
    required String email,
    required String fullName,
    required String cpfMaskedOrDigits,
  });
}

class UserProfileDataSourceImpl implements UserProfileDataSource {
  final FirebaseFirestore db;

  UserProfileDataSourceImpl(this.db);

  CollectionReference<Map<String, dynamic>> get _users =>
      db.collection('users');
  CollectionReference<Map<String, dynamic>> get _cpfIndex =>
      db.collection('cpfIndex');

  @override
  Future<Map<String, dynamic>?> getProfileByUid(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Future<void> upsertProfile({
    required String uid,
    required String email,
    required String fullName,
    required String cpfMaskedOrDigits,
  }) async {
    if (uid.trim().isEmpty) throw 'UID inválido.';
    final cleanEmail = email.trim().toLowerCase();

    final newCpf = CpfValidator.onlyDigits(cpfMaskedOrDigits);
    if (!CpfValidator.isValid(newCpf)) {
      throw 'CPF inválido (11 dígitos).';
    }

    final userRef = _users.doc(uid);

    await db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final currentData = userSnap.data() ?? <String, dynamic>{};
      final oldCpf = (currentData['cpf'] ?? '').toString();

      // Verifica unicidade do novo CPF
      final idxRef = _cpfIndex.doc(newCpf);
      final idxSnap = await tx.get(idxRef);

      if (idxSnap.exists) {
        final owner = (idxSnap.data()?['uid'])?.toString();
        if (owner != null && owner != uid) {
          throw 'Esse CPF já está em uso por outra conta.';
        }
      }

      // Atualiza /users/{uid}
      tx.set(userRef, {
        'fullName': fullName.trim(),
        'cpf': newCpf,
        'email': cleanEmail,
        // mantém saldo existente (se não existir, cria 0)
        'balance': ((currentData['balance'] ?? 0) as num).toDouble(),
        'createdAt': currentData['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Atualiza/Cria índice do CPF atual
      tx.set(idxRef, {
        'uid': uid,
        'cpf': newCpf,
        'fullName': fullName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Se CPF antigo for diferente e pertence a mim, remove índice antigo
      if (oldCpf.isNotEmpty && oldCpf != newCpf) {
        final oldIdxRef = _cpfIndex.doc(oldCpf);
        final oldIdxSnap = await tx.get(oldIdxRef);

        if (oldIdxSnap.exists) {
          final owner = (oldIdxSnap.data()?['uid'])?.toString();
          if (owner == uid) {
            tx.delete(oldIdxRef);
          }
        }
      }
    });
  }
}
