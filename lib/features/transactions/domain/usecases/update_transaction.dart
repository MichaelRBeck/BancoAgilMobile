import '../../data/models/transaction_model.dart';
import '../repositories/transactions_repository.dart';

class UpdateTransaction {
  final TransactionsRepository repo;
  UpdateTransaction(this.repo);

  Future<void> call(TransactionModel model) => repo.update(model);
}
