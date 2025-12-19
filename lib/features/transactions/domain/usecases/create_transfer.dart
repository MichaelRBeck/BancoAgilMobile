import '../entities/transaction.dart';
import '../repositories/transactions_repository.dart';

class CreateTransfer {
  final TransactionsRepository repo;
  CreateTransfer(this.repo);

  Future<void> call({
    required String originUid,
    required String originCpf,
    required String destCpf,
    required double amount,
    String? description,
  }) {
    final now = DateTime.now();

    final tx = Transaction(
      id: '', // vazio para o datasource gerar docId (add)
      userId: originUid, // dono do registro
      type: 'transfer',
      category: 'transfer',
      amount: amount,
      date: now,
      notes: description,

      originUid: originUid,
      originCpf: originCpf,
      destCpf: destCpf,

      // você pode popular conforme sua regra atual:
      status: 'completed',
      counterpartyCpf: destCpf,

      createdAt: now,
      updatedAt: now,
    );

    return repo.create(tx);
  }
}
