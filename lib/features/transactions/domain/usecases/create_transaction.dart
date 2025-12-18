import '../entities/transaction.dart';
import '../repositories/transactions_repository.dart';

class CreateTransaction {
  final TransactionsRepository repo;
  CreateTransaction(this.repo);

  Future<void> call(Transaction entity) => repo.create(entity);
}
