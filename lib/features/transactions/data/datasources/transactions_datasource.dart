import '../models/transaction_model.dart';
import '../dto/transactions_cursor_dto.dart';

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

  Future<void> create({required String uid, required TransactionModel model});
  Future<void> update({required String uid, required TransactionModel model});
  Future<void> delete({required String uid, required String id});

  Future<void> updateTransferNotes({
    required String uid,
    required String id,
    required String notes,
  });
}
