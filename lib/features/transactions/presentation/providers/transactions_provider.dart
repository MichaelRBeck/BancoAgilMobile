import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';

import '../../data/models/transaction_model.dart';
import '../../domain/usecases/get_transactions_page.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/calc_totals.dart';
import 'transactions_filters_provider.dart';

class TransactionsProvider extends ChangeNotifier {
  final GetTransactionsPage getPage;
  final DeleteTransaction deleteTx;
  final CalcTotals calcTotals;

  TransactionsProvider({
    required this.getPage,
    required this.deleteTx,
    required this.calcTotals,
  });

  final List<TransactionModel> _items = [];
  List<TransactionModel> get items => List.unmodifiable(_items);

  bool loading = false;
  bool totalsLoading = false;
  bool end = false;

  double sumIncome = 0;
  double sumExpense = 0;
  double sumTransferNet = 0;

  String? _uid;
  TransactionsFiltersProvider? _filters;

  static const int _limit = 20;
  fs.DocumentSnapshot? _cursor;

  void apply(String? uid, TransactionsFiltersProvider filters) {
    final uidChanged = uid != _uid;
    final filtersChanged = _filters != filters;

    _uid = uid;
    _filters = filters;

    if (uidChanged || filtersChanged) {
      refresh();
    }
  }

  Future<void> refresh() async {
    if (_uid == null || _uid!.isEmpty) {
      _items.clear();
      _cursor = null;
      end = false;
      _recalcTotals();
      notifyListeners();
      return;
    }

    loading = true;
    end = false;
    _cursor = null;
    _items.clear();
    notifyListeners();

    try {
      final result = await getPage(
        uid: _uid!,
        type: _filters?.type ?? '',
        start: _filters?.start,
        end: _filters?.end,
        counterpartyCpf: _filters?.counterpartyCpf ?? '',
        limit: _limit,
        startAfter: null,
      );

      _items.addAll(result.items);
      _cursor = result.nextCursor;
      end = !result.hasMore;

      _recalcTotals();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || end) return;
    if (_uid == null || _uid!.isEmpty) return;

    loading = true;
    notifyListeners();

    try {
      final result = await getPage(
        uid: _uid!,
        type: _filters?.type ?? '',
        start: _filters?.start,
        end: _filters?.end,
        counterpartyCpf: _filters?.counterpartyCpf ?? '',
        limit: _limit,
        startAfter: _cursor,
      );

      _items.addAll(result.items);
      _cursor = result.nextCursor;
      end = !result.hasMore;

      _recalcTotals();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    await deleteTx(id);
    _items.removeWhere((t) => t.id == id);
    _recalcTotals();
    notifyListeners();
  }

  void _recalcTotals() {
    totalsLoading = true;

    final r = calcTotals(_items);
    sumIncome = r.income;
    sumExpense = r.expense;
    sumTransferNet = r.transferNet;

    totalsLoading = false;
  }
}
