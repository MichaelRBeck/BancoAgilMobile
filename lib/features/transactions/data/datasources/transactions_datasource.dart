import '../models/transaction_model.dart';
import '../dto/transactions_cursor_dto.dart'; // vamos criar já já

class TransactionsPageDto {
  final List<TransactionModel> items;
  final TransactionsCursorDto? nextCursor;
  final bool hasMore;

  const TransactionsPageDto({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

abstract class TransactionsDataSource {
  Future<TransactionsPageDto> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    TransactionsCursorDto? startAfter,
    String? counterpartyCpf,
  });

  Future<void> create(TransactionModel model);
  Future<void> update(TransactionModel model);
  Future<void> delete(String id);

  Future<void> updateTransferNotes({required String id, required String notes});
}
