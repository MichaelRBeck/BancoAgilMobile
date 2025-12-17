import '../repositories/transactions_repository.dart';

class DeleteTransaction {
  final TransactionsRepository repo;
  DeleteTransaction(this.repo);

  Future<void> call(String id) => repo.delete(id);
}
