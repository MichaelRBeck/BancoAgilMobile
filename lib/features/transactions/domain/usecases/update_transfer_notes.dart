import '../repositories/transactions_repository.dart';

class UpdateTransferNotes {
  final TransactionsRepository repo;
  UpdateTransferNotes(this.repo);

  Future<void> call({
    required String uid,
    required String id,
    required String notes,
  }) {
    return repo.updateTransferNotes(uid: uid, id: id, notes: notes);
  }
}
