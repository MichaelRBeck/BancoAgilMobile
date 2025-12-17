import 'package:flutter/foundation.dart';

import '../../../../core/utils/cpf_input_formatter.dart';
import '../../domain/entities/transactions_filter.dart';

class TransactionsFiltersProvider extends ChangeNotifier {
  TransactionsFilter _filter = const TransactionsFilter();
  TransactionsFilter get filter => _filter;

  String get type => _filter.type;
  DateTime? get start => _filter.start;
  DateTime? get end => _filter.end;
  String get counterpartyCpf => _filter.counterpartyCpfDigits;

  void setType(String t) {
    if (_filter.type == t) return;
    _filter = _filter.copyWith(type: t);
    notifyListeners();
  }

  void setRange(DateTime? start, DateTime? end) {
    if (_filter.start == start && _filter.end == end) return;
    _filter = _filter.copyWith(start: start, end: end);
    notifyListeners();
  }

  void setCounterpartyCpf(String? cpf) {
    final normalized = cpf == null ? '' : CpfInputFormatter.digits(cpf);
    if (_filter.counterpartyCpfDigits == normalized) return;
    _filter = _filter.copyWith(counterpartyCpfDigits: normalized);
    notifyListeners();
  }

  void clear() {
    _filter = const TransactionsFilter();
    notifyListeners();
  }
}
