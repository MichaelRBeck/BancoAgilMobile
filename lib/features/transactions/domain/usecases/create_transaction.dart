import '../../data/models/transaction_model.dart';
import '../repositories/transactions_repository.dart';

class CreateTransaction {
  final TransactionsRepository repo;
  CreateTransaction(this.repo);

  Future<void> call(TransactionModel model) => repo.create(model);
}
