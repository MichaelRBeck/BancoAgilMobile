import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/transaction.dart';
import '../../data/datasources/transactions_remote_datasource.dart';
import '../../../../state/filters_provider.dart';

class TransactionsProvider extends ChangeNotifier {
  final TransactionsService service;

  TransactionsProvider({required this.service});

  // Parâmetros atuais
  String? _uid;
  String _type = '';
  DateTime? _start;
  DateTime? _endDate;
  String _counterpartyCpf = '';

  // Estado da lista
  final List<TransactionModel> _items = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _isEnd = false;

  // Totais
  bool _totalsLoading = false;
  double _sumIncome = 0, _sumExpense = 0;
  double _sumTransferIn = 0, _sumTransferOut = 0, _sumTransferNet = 0;

  List<TransactionModel> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get end => _isEnd;
  bool get totalsLoading => _totalsLoading;

  double get sumIncome => _sumIncome;
  double get sumExpense => _sumExpense;
  double get sumTransferIn => _sumTransferIn;
  double get sumTransferOut => _sumTransferOut;
  double get sumTransferNet => _sumTransferNet;

  /// Chamado pelo ProxyProvider quando auth/filtros mudam
  void apply(String? uid, FiltersProvider filters) {
    final changed =
        _uid != uid ||
        _type != filters.type ||
        _start != filters.start ||
        _endDate != filters.end ||
        _counterpartyCpf != filters.counterpartyCpf;

    _uid = uid;
    _type = filters.type;
    _start = filters.start;
    _endDate = filters.end;
    _counterpartyCpf = filters.counterpartyCpf;

    if (changed) refresh();
  }

  bool _matchesCpf(TransactionModel t) {
    if (_type != 'transfer' || _counterpartyCpf.isEmpty) return true;
    String digits(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');
    final docCpf = digits(t.counterpartyCpf ?? t.destCpf);
    final f = _counterpartyCpf;
    if (f.length == 11) return docCpf == f;
    return docCpf.startsWith(f);
  }

  Future<void> refresh() async {
    if (_uid == null) return;
    _loading = true;
    _isEnd = false;
    _items.clear();
    _lastDoc = null;
    notifyListeners();

    try {
      final (list, last) = await service.fetchPage(
        uid: _uid!,
        type: _type.isEmpty ? null : _type,
        start: _start,
        end: _endDate,
        limit: 20,
      );
      final filtered = list.where(_matchesCpf).toList();
      _items.addAll(filtered);
      _lastDoc = last;
      _isEnd = last == null && filtered.length < list.length
          ? false
          : last == null;
    } finally {
      _loading = false;
      notifyListeners();
    }

    _calcTotals();
  }

  Future<void> loadMore() async {
    if (_uid == null || _isEnd || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final (list, last) = await service.fetchPage(
        uid: _uid!,
        type: _type.isEmpty ? null : _type,
        start: _start,
        end: _endDate,
        limit: 20,
        startAfter: _lastDoc,
      );
      final filtered = list.where(_matchesCpf).toList();
      _items.addAll(filtered);
      _lastDoc = last;
      _isEnd = last == null && filtered.length < list.length
          ? false
          : last == null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    await service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    _calcTotals();
  }

  Future<void> _calcTotals() async {
    if (_uid == null) return;
    _totalsLoading = true;
    notifyListeners();
    try {
      final t = await service.totalsForPeriod(
        uid: _uid!,
        start: _start,
        end: _endDate,
        type: _type.isEmpty ? null : _type,
        counterpartyCpf: _counterpartyCpf.isEmpty ? null : _counterpartyCpf,
      );
      _sumIncome = t.income;
      _sumExpense = t.expense;
      _sumTransferIn = t.transferIn;
      _sumTransferOut = t.transferOut;
      _sumTransferNet = t.transferNet;
    } finally {
      _totalsLoading = false;
      notifyListeners();
    }
  }
}
