import '../../domain/entities/transaction.dart';
import '../../domain/entities/transactions_cursor.dart';

enum TransactionsStatus { idle, loading, success, error }

class TransactionsTotals {
  final double income;
  final double expense;
  final double transferNet;

  const TransactionsTotals({
    required this.income,
    required this.expense,
    required this.transferNet,
  });

  factory TransactionsTotals.zero() =>
      const TransactionsTotals(income: 0, expense: 0, transferNet: 0);
}

class TransactionsState {
  final TransactionsStatus status;
  final List<Transaction> items;
  final TransactionsCursor? cursor;
  final bool hasMore;
  final TransactionsTotals totals;
  final bool totalsLoading;
  final String? error;

  const TransactionsState({
    required this.status,
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.totals,
    required this.totalsLoading,
    required this.error,
  });

  factory TransactionsState.initial() => TransactionsState(
    status: TransactionsStatus.idle,
    items: const [],
    cursor: null,
    hasMore: true,
    totals: TransactionsTotals.zero(),
    totalsLoading: false,
    error: null,
  );

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? items,
    TransactionsCursor? cursor,
    bool? hasMore,
    TransactionsTotals? totals,
    bool? totalsLoading,
    String? error,
    bool clearError = false,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      totals: totals ?? this.totals,
      totalsLoading: totalsLoading ?? this.totalsLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
