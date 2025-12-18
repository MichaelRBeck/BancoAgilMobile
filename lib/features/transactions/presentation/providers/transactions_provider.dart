import 'package:flutter/foundation.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/usecases/calc_totals.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions_page.dart';
import '../providers/transactions_filters_provider.dart';
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
        type: (_filters?.type.trim().isEmpty ?? true)
            ? null
            : _filters!.type.trim(),
        start: _filters?.start,
        end: _filters?.end,
        counterpartyCpf: _filters?.counterpartyCpf ?? '',
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
      // mantém itens vazios e mostra erro
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

    _emit(
      _state.copyWith(status: TransactionsStatus.loading, clearError: true),
    );

    try {
      final result = await getPage(
        uid: uid,
        type: (_filters?.type.trim().isEmpty ?? true)
            ? null
            : _filters!.type.trim(),
        start: _filters?.start,
        end: _filters?.end,
        counterpartyCpf: _filters?.counterpartyCpf ?? '',
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
      // não zera lista no loadMore, só reporta erro e volta status
      _emit(
        _state.copyWith(status: TransactionsStatus.error, error: e.toString()),
      );
      // opcional: voltar para success se você não quer que UI “entre em erro”
      _emit(_state.copyWith(status: TransactionsStatus.success));
    }
  }

  Future<void> delete(String id) async {
    try {
      await deleteTx(id);
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
    // Se quiser deixar “by the book”, o ideal é totals ser um usecase separado.
    // Mas pra fechar o requisito de state avançado, já está ótimo.
    final r = calcTotals(items);
    return TransactionsTotals(
      income: r.income,
      expense: r.expense,
      transferNet: r.transferNet,
    );
  }
}
