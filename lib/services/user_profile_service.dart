import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/cpf_validator.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _cpfIndex => _db.collection('cpfIndex');

  Future<UserProfile?> getCurrentProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  /// Cria/atualiza o perfil do usuário logado e mantém unicidade do CPF via cpfIndex/{cpf}
  Future<void> upsertOwnProfile({
    required String fullName,
    required String cpfMaskedOrDigits,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Não autenticado.';

    final newCpf = CpfValidator.onlyDigits(cpfMaskedOrDigits);
    if (!CpfValidator.isValid(newCpf)) {
      throw 'CPF inválido (11 dígitos).';
    }

    final uid = user.uid;
    final userRef = _users.doc(uid);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final currentData = (userSnap.data() as Map<String, dynamic>?) ?? {};
      final oldCpf = (currentData['cpf'] ?? '').toString();

      // Verifica unicidade do novo CPF
      final idxRef = _cpfIndex.doc(newCpf);
      final idxSnap = await tx.get(idxRef);
      if (idxSnap.exists) {
        final owner = (idxSnap.data() as Map<String, dynamic>)['uid']
            ?.toString();
        if (owner != uid) {
          throw 'Esse CPF já está em uso por outra conta.';
        }
      }

      // Atualiza /users/{uid}
      tx.set(userRef, {
        'fullName': fullName.trim(),
        'cpf': newCpf,
        'email': user.email?.toLowerCase() ?? '',
        'balance': (currentData['balance'] ?? 0).toDouble(),
        'createdAt': currentData['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Atualiza/Cria índice do CPF atual
      tx.set(idxRef, {
        'uid': uid,
        'cpf': newCpf,
        'fullName': fullName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Se CPF antigo for diferente e pertence a mim, remove índice antigo
      if (oldCpf.isNotEmpty && oldCpf != newCpf) {
        final oldIdxRef = _cpfIndex.doc(oldCpf);
        final oldIdxSnap = await tx.get(oldIdxRef);
        if (oldIdxSnap.exists) {
          final owner = (oldIdxSnap.data() as Map<String, dynamic>)['uid']
              ?.toString();
          if (owner == uid) {
            tx.delete(oldIdxRef);
          }
        }
      }
    });
  }
}
