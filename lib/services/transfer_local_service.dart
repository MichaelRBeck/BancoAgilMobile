/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/cpf_validator.dart';
import '../core/utils/cpf_input_formatter.dart';

class TransferLocalService {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  TransferLocalService({FirebaseFirestore? db, FirebaseAuth? auth})
    : db = db ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;

  Future<void> createTransfer({
    required String destCpf,
    required double amount,
    String? description,
  }) async {
    final cpfDigits = CpfValidator.onlyDigits(destCpf);
    if (!CpfValidator.isValid(cpfDigits)) {
      throw 'CPF do destinatário inválido (precisa ter 11 dígitos).';
    }
    if (amount <= 0) throw 'Informe um valor maior que zero.';

    final originUser = auth.currentUser;
    if (originUser == null) throw 'Não autenticado.';

    String? destUid;
    String? destName;

    // 1) Índice cpfIndex/{cpf}
    final idxSnap = await db.collection('cpfIndex').doc(cpfDigits).get();
    if (idxSnap.exists) {
      final idx = idxSnap.data() as Map<String, dynamic>;
      destUid = (idx['uid'] ?? '').toString();
      destName = (idx['fullName'] ?? '').toString();
    }

    // 2) Fallback /users por cpf sem máscara
    if (destUid == null || destUid.isEmpty) {
      final q = await db
          .collection('users')
          .where('cpf', isEqualTo: cpfDigits)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final u = q.docs.first;
        destUid = u.id;
        final data = u.data();
        destName = (data['fullName'] ?? '').toString();
      }
    }

    // 3) Fallback /users por cpf mascarado
    if (destUid == null || destUid.isEmpty) {
      final masked = CpfInputFormatter.format(cpfDigits);
      final q = await db
          .collection('users')
          .where('cpf', isEqualTo: masked)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final u = q.docs.first;
        destUid = u.id;
        final data = u.data();
        destName = (data['fullName'] ?? '').toString();
      }
    }

    if (destUid == null || destUid.isEmpty)
      throw 'Destinatário não encontrado.';
    if (originUser.uid == destUid)
      throw 'Não é possível transferir para si mesmo.';

    final originRef = db.collection('users').doc(originUser.uid);
    final destRef = db.collection('users').doc(destUid);

    await db.runTransaction((tx) async {
      final originSnap = await tx.get(originRef);
      final destSnap = await tx.get(destRef);

      if (!originSnap.exists) throw 'Usuário remetente não encontrado.';
      if (!destSnap.exists) throw 'Usuário destinatário não encontrado.';

      final od = originSnap.data() as Map<String, dynamic>;
      final dd = destSnap.data() as Map<String, dynamic>;

      final originBalance = (od['balance'] ?? 0).toDouble();
      final destBalance = (dd['balance'] ?? 0).toDouble();

      final originCpf = (od['cpf'] ?? '').toString();
      final originName = (od['fullName'] ?? '').toString();
      final destCpfDb = (dd['cpf'] ?? '').toString();

      if (originBalance < amount) throw 'Saldo insuficiente.';

      final now = FieldValue.serverTimestamp();

      tx.update(originRef, {
        'balance': originBalance - amount,
        'updatedAt': now,
      });
      tx.update(destRef, {'balance': destBalance + amount, 'updatedAt': now});

      final tOriginRef = db.collection('transactions').doc();
      tx.set(tOriginRef, {
        'userId': originUser.uid,
        'type': 'transfer',
        'category': 'Transferência enviada',
        'amount': amount,
        'date': now,
        'notes': description ?? '',
        'createdAt': now,
        'updatedAt': now,
        'originUid': originUser.uid,
        'destUid': destUid,
        'originCpf': originCpf,
        'destCpf': destCpfDb,
        'status': 'completed',
        'counterpartyUid': destUid,
        'counterpartyCpf': destCpfDb,
        'counterpartyName': destName ?? '',
      });

      final tDestRef = db.collection('transactions').doc();
      tx.set(tDestRef, {
        'userId': destUid,
        'type': 'transfer',
        'category': 'Transferência recebida',
        'amount': amount,
        'date': now,
        'notes': description ?? '',
        'createdAt': now,
        'updatedAt': now,
        'originUid': originUser.uid,
        'destUid': destUid,
        'originCpf': originCpf,
        'destCpf': destCpfDb,
        'status': 'completed',
        'counterpartyUid': originUser.uid,
        'counterpartyCpf': originCpf,
        'counterpartyName': originName,
      });
    });
  }
}
*/
