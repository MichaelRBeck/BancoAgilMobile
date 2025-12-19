import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../user/domain/repositories/user_repository.dart';
import '../repositories/transactions_repository.dart';
import '../entities/transaction.dart';

class ExecuteTransfer {
  final FirebaseFirestore firestore;
  final UserRepository userRepo;
  final TransactionsRepository txRepo;

  ExecuteTransfer({
    required this.firestore,
    required this.userRepo,
    required this.txRepo,
  });

  Future<void> call({
    required String originUid,
    required String originCpf,
    required String destCpf,
    required double amount,
    String? description,
  }) async {
    if (amount <= 0) {
      throw Exception('Valor inválido');
    }

    final originRef = firestore.collection('users').doc(originUid);

    await firestore.runTransaction((tx) async {
      final originSnap = await tx.get(originRef);

      final originBalance = (originSnap['balance'] as num?)?.toDouble() ?? 0;

      if (originBalance < amount) {
        throw Exception('Saldo insuficiente');
      }

      // 🔻 debita saldo
      tx.update(originRef, {'balance': originBalance - amount});

      // 🔺 cria transação
      final now = DateTime.now();
      final txRef = firestore.collection('transactions').doc();

      tx.set(txRef, {
        'id': txRef.id,
        'userId': originUid,
        'type': 'transfer',
        'category': 'transfer',
        'amount': amount,
        'date': Timestamp.fromDate(now),
        'notes': description,
        'originUid': originUid,
        'originCpf': originCpf,
        'destCpf': destCpf,
        'status': 'completed',
        'counterpartyCpf': destCpf,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }
}
