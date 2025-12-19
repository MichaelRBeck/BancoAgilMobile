import 'dart:async';

import 'package:bancoagil/features/transactions/domain/entities/transactions_page_result.dart';
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

  StreamSubscription<String>? _filtersSub;

  static const int _limit = 20;

  // ----------------------------
  // Prefetch (pré-carregamento)
  // ----------------------------
  bool _prefetching = false;
  TransactionsPageResult? _prefetched;
  String? _prefetchKey;
  // ----------------------------

  void _emit(TransactionsState s) {
    _state = s;
    notifyListeners();
  }

  void apply(String? uid, TransactionsFiltersProvider filters) {
    final uidChanged = uid != _uid;
    final filtersInstanceChanged = !identical(filters, _filters);

    _uid = uid;
    _filters = filters;

    // (1) assina o Stream reativo do provider de filtros
    if (filtersInstanceChanged) {
      _filtersSub?.cancel();
      _filtersSub = filters.changes.listen((sig) {
        // evita refresh duplicado desnecessário
        if (sig == _filtersSig) return;
        _filtersSig = sig;

        _clearPrefetch();
        refresh();
      });
    }

    // (2) garante refresh quando troca de usuário (login/logout)
    if (uidChanged) {
      _filtersSig = filters.signature; // atualiza sig base
      _clearPrefetch();
      refresh();
      return;
    }

    // (3) primeira aplicação (ex: tela abriu) — se nunca carregou ainda
    if (_filtersSig == null) {
      _filtersSig = filters.signature;
      _clearPrefetch();
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

  String _contextKey({required String uid, required String cursorId}) {
    final type = _normalizedType() ?? '';
    final start = _filters?.start?.millisecondsSinceEpoch ?? 0;
    final end = _filters?.end?.millisecondsSinceEpoch ?? 0;
    final cpf = _normalizedCounterpartyCpf() ?? '';
    return '$uid|$type|$start|$end|$cpf|$cursorId';
  }

  void _clearPrefetch() {
    _prefetching = false;
    _prefetched = null;
    _prefetchKey = null;
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _clearPrefetch();
      _emit(
        TransactionsState.initial().copyWith(
          hasMore: true,
          totals: _calcTotals(const []),
        ),
      );
      return;
    }

    _clearPrefetch();

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

      _maybePrefetchNext();
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
    if (cursor == null) return;

    final key = _contextKey(uid: uid, cursorId: cursor.docId);

    if (_prefetched != null && _prefetchKey == key) {
      final result = _prefetched!;
      _prefetched = null;
      _prefetchKey = null;

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

      _maybePrefetchNext();
      return;
    }

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

      _maybePrefetchNext();
    } catch (e) {
      _emit(
        _state.copyWith(status: TransactionsStatus.error, error: e.toString()),
      );
      _emit(_state.copyWith(status: TransactionsStatus.success));
    }
  }

  void _maybePrefetchNext() {
    if (_prefetching) return;

    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    if (!_state.hasMore) return;

    final cursor = _state.cursor;
    if (cursor == null) return;

    final key = _contextKey(uid: uid, cursorId: cursor.docId);
    if (_prefetchKey == key && _prefetched != null) return;

    _prefetching = true;
    _prefetchKey = key;

    () async {
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

        if (_prefetchKey != key) return;
        _prefetched = result;
      } catch (_) {
        // ignora falhas do prefetch
      } finally {
        if (_prefetchKey == key) _prefetching = false;
      }
    }();
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await deleteTx(uid: uid, id: id);

      final next = _state.items
          .where((t) => t.id != id)
          .toList(growable: false);

      _clearPrefetch();

      _emit(
        _state.copyWith(
          items: List.unmodifiable(next),
          totals: _calcTotals(next),
          clearError: true,
        ),
      );

      _maybePrefetchNext();
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

  @override
  void dispose() {
    _filtersSub?.cancel();
    super.dispose();
  }
}
