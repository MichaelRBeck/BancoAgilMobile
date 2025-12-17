import '../repositories/transactions_repository.dart';

class CreateTransfer {
  final TransactionsRepository repo;
  CreateTransfer(this.repo);

  Future<void> call({
    required String destCpf,
    required double amount,
    String? description,
  }) {
    return repo.createTransfer(
      destCpf: destCpf,
      amount: amount,
      description: description,
    );
  }
}
