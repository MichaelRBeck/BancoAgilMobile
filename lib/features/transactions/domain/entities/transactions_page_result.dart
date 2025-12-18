import 'transaction.dart';
import 'transactions_cursor.dart';

class TransactionsPageResult {
  final List<Transaction> items;
  final TransactionsCursor? nextCursor;
  final bool hasMore;

  const TransactionsPageResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}
