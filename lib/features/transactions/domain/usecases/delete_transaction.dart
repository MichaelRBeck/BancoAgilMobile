import '../repositories/transactions_repository.dart';

class DeleteTransaction {
  final TransactionsRepository repo;
  DeleteTransaction(this.repo);

  Future<void> call({required String uid, required String id}) {
    return repo.delete(id, uid: uid);
  }
}
