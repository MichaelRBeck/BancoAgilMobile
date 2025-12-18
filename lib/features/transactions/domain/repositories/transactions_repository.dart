import '../entities/transaction.dart';
import '../entities/transactions_cursor.dart';
import '../entities/transactions_page_result.dart';

abstract class TransactionsRepository {
  Future<TransactionsPageResult> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    TransactionsCursor? startAfter,
    String? counterpartyCpf,
  });

  Future<void> create(Transaction entity);
  Future<void> update(Transaction entity);
  Future<void> delete(String id);

  Future<void> createTransfer({
    required String destCpf,
    required double amount,
    String? description,
  });

  Future<void> updateTransferNotes({required String id, required String notes});
}
