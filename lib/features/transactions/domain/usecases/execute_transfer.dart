import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/transactions_repository.dart';
import '../../../../core/utils/cpf_utils.dart';

class ExecuteTransfer {
  final FirebaseFirestore firestore;
  final TransactionsRepository txRepo;

  ExecuteTransfer({required this.firestore, required this.txRepo});

  Future<void> call({
    required String originUid,
    required String originCpf,
    required String destCpf,
    required double amount,
    String? description,
  }) async {
    if (amount <= 0) throw Exception('Valor inválido');

    final originCpfDigits = CpfUtils.digits(originCpf);
    final destCpfDigits = CpfUtils.digits(destCpf);

    // 1) resolve destUid via cpfIndex (GET no doc exato)
    final cpfIndexRef = firestore.collection('cpfIndex').doc(destCpfDigits);
    final cpfIndexSnap = await cpfIndexRef.get();

    if (!cpfIndexSnap.exists) {
      throw Exception('CPF do destinatário não encontrado.');
    }

    final destUid = (cpfIndexSnap.data()?['uid'] as String?)?.trim();
    if (destUid == null || destUid.isEmpty) {
      throw Exception('CPF do destinatário inválido no índice.');
    }

    if (destUid == originUid) {
      throw Exception('Não é possível transferir para você mesmo.');
    }

    final originRef = firestore.collection('users').doc(originUid);
    final destRef = firestore.collection('users').doc(destUid);

    await firestore.runTransaction((tx) async {
      // ✅ pode ler apenas o próprio usuário (origem)
      final originSnap = await tx.get(originRef);
      if (!originSnap.exists) {
        throw Exception('Usuário de origem não encontrado.');
      }

      final originBalance =
          (originSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

      if (originBalance < amount) {
        throw Exception('Saldo insuficiente');
      }

      // 🔻 debita origem (owner update)
      tx.update(originRef, {
        'balance': originBalance - amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔺 credita destino SEM ler doc (evita permission denied)
      // requer rule permitindo update de terceiros em balance/updatedAt
      tx.update(destRef, {
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🧾 cria 2 transações (origem e destino)
      final now = DateTime.now();
      final col = firestore.collection('transactions');

      final originTxRef = col.doc();
      final destTxRef = col.doc();

      // Transação da ORIGEM (counterparty = destinatário)
      tx.set(originTxRef, {
        'userId': originUid,
        'type': 'transfer',
        'category': 'transfer',
        'amount': amount,
        'date': Timestamp.fromDate(now),
        'notes': description ?? '',
        'originUid': originUid,
        'originCpf': originCpfDigits,
        'destUid': destUid,
        'destCpf': destCpfDigits,
        'status': 'completed',

        'counterpartyUid': destUid,
        'counterpartyCpf': destCpfDigits,
        'counterpartyName': null,

        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Transação do DESTINO (counterparty = remetente)
      tx.set(destTxRef, {
        'userId': destUid,
        'type': 'transfer',
        'category': 'transfer',
        'amount': amount,
        'date': Timestamp.fromDate(now),
        'notes': description ?? '',
        'originUid': originUid,
        'originCpf': originCpfDigits,
        'destUid': destUid,
        'destCpf': destCpfDigits,
        'status': 'completed',

        'counterpartyUid': originUid,
        'counterpartyCpf': originCpfDigits,
        'counterpartyName': null,

        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    // ✅ invalida cache (origem e destino)
    await txRepo.invalidateUserCache(originUid);
    await txRepo.invalidateUserCache(destUid);
  }
}
