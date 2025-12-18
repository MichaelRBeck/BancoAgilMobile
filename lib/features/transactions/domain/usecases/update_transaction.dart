import '../entities/transaction.dart';
import '../repositories/transactions_repository.dart';

class UpdateTransaction {
  final TransactionsRepository repo;
  UpdateTransaction(this.repo);

  Future<void> call(Transaction entity) => repo.update(entity);
}
