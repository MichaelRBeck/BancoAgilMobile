import 'package:flutter/foundation.dart';
import '../utils/cpf_input_formatter.dart';

class FiltersProvider extends ChangeNotifier {
  // '', 'income', 'expense', 'transfer'
  String _type = '';
  DateTime? _start;
  DateTime? _end;

  // Filtro por CPF do destinatário (só dígitos)
  String _counterpartyCpf = '';

  String get type => _type;
  DateTime? get start => _start;
  DateTime? get end => _end;
  String get counterpartyCpf => _counterpartyCpf;

  void setType(String t) {
    if (_type == t) return;
    _type = t;
    notifyListeners();
  }

  void setRange(DateTime? start, DateTime? end) {
    final changed = _start != start || _end != end;
    if (!changed) return;
    _start = start;
    _end = end;
    notifyListeners();
  }

  void setCounterpartyCpf(String? cpf) {
    final normalized = cpf == null ? '' : CpfInputFormatter.digits(cpf);
    if (_counterpartyCpf == normalized) return;
    _counterpartyCpf = normalized;
    notifyListeners();
  }

  void clear() {
    _type = '';
    _start = null;
    _end = null;
    _counterpartyCpf = '';
    notifyListeners();
  }
}
