import 'package:flutter/foundation.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/usecases/calc_totals.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions_page.dart';
import 'transactions_filters_provider.dart';
import 'transactions_state.dart';

class TransactionsProvider extends ChangeNotifier {
  final GetTransactionsPage getPage;
  final DeleteTransaction deleteTx;
  final CalcTotals calcTotals;

  TransactionsProvider({
    required this.getPage,
    required this.deleteTx,
    required this.calcTotals,
  });

  TransactionsState _state = TransactionsState.initial();
  TransactionsState get state => _state;

  // ✅ Getters compatíveis (pra não quebrar tela)
  List<Transaction> get items => _state.items;
  bool get loading => _state.status == TransactionsStatus.loading;
  bool get end => !_state.hasMore;
  bool get totalsLoading => _state.totalsLoading;

  double get sumIncome => _state.totals.income;
  double get sumExpense => _state.totals.expense;
  double get sumTransferNet => _state.totals.transferNet;

  String? get error => _state.error;
  String? _filtersSig;

  String? _uid;
  TransactionsFiltersProvider? _filters;

  static const int _limit = 20;

  void _emit(TransactionsState s) {
    _state = s;
    notifyListeners();
  }

  void apply(String? uid, TransactionsFiltersProvider filters) {
    final uidChanged = uid != _uid;
    final newSig = filters.signature;
    final sigChanged = newSig != _filtersSig;

    _uid = uid;
    _filters = filters;
    _filtersSig = newSig;

    if (uidChanged || sigChanged) {
      refresh();
    }
  }

  String? _normalizedType() {
    final t = _filters?.type.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  String? _normalizedCounterpartyCpf() {
    final c = _filters?.counterpartyCpf.trim() ?? '';
    return c.isEmpty ? null : c;
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _emit(
        TransactionsState.initial().copyWith(
          hasMore: true,
          totals: _calcTotals(const []),
        ),
      );
      return;
    }

    _emit(
      _state.copyWith(
        status: TransactionsStatus.loading,
        items: const [],
        cursor: null,
        hasMore: true,
        totalsLoading: false,
        clearError: true,
      ),
    );

    try {
      final result = await getPage(
        uid: uid,
        type: _normalizedType(),
        start: _filters?.start,
        end: _filters?.end,
        counterpartyCpf: _normalizedCounterpartyCpf(),
        limit: _limit,
        startAfter: null,
      );

      final newItems = List<Transaction>.unmodifiable(result.items);

      _emit(
        _state.copyWith(
          status: TransactionsStatus.success,
          items: newItems,
          cursor: result.nextCursor,
          hasMore: result.hasMore,
          totals: _calcTotals(newItems),
          totalsLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          status: TransactionsStatus.error,
          items: const [],
          cursor: null,
          hasMore: true,
          totals: TransactionsTotals.zero(),
          totalsLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (loading || end) return;

    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    final cursor = _state.cursor;

    // Mantém items e apenas sinaliza loading
    _emit(
      _state.copyWith(status: TransactionsStatus.loading, clearError: true),
    );

    try {
      final result = await getPage(
        uid: uid,
        type: _normalizedType(),
        start: _filters?.start,
        end: _filters?.end,
        counterpartyCpf: _normalizedCounterpartyCpf(),
        limit: _limit,
        startAfter: cursor,
      );

      final merged = List<Transaction>.unmodifiable([
        ..._state.items,
        ...result.items,
      ]);

      _emit(
        _state.copyWith(
          status: TransactionsStatus.success,
          items: merged,
          cursor: result.nextCursor,
          hasMore: result.hasMore,
          totals: _calcTotals(merged),
          totalsLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      // Não zera lista no loadMore
      _emit(
        _state.copyWith(status: TransactionsStatus.error, error: e.toString()),
      );
      _emit(_state.copyWith(status: TransactionsStatus.success));
    }
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await deleteTx(uid: uid, id: id);

      final next = _state.items
          .where((t) => t.id != id)
          .toList(growable: false);

      _emit(
        _state.copyWith(
          items: List.unmodifiable(next),
          totals: _calcTotals(next),
          clearError: true,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(error: e.toString(), status: TransactionsStatus.error),
      );
      _emit(_state.copyWith(status: TransactionsStatus.success));
    }
  }

  TransactionsTotals _calcTotals(List<Transaction> items) {
    final r = calcTotals(items);
    return TransactionsTotals(
      income: r.income,
      expense: r.expense,
      transferNet: r.transferNet,
    );
  }
}
