import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/cpf_input_formatter.dart';

class TransactionsFiltersProvider extends ChangeNotifier {
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

  /// ---------------------------
  /// REATIVO (Stream de mudanças)
  /// ---------------------------
  final _changesCtrl = StreamController<String>.broadcast();
  Stream<String> get changes => _changesCtrl.stream;

  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 400);

  String get signature {
    final s = start?.millisecondsSinceEpoch ?? 0;
    final e = end?.millisecondsSinceEpoch ?? 0;
    return '${type.trim()}|$s|$e|${counterpartyCpf.trim()}';
  }

  void _emitChange({bool debounced = false}) {
    // sempre mantém UI reativa via Provider
    notifyListeners();

    // e também emite para quem quiser reagir via Stream
    if (!debounced) {
      // emite imediatamente
      if (!_changesCtrl.isClosed) _changesCtrl.add(signature);
      return;
    }

    // emite com debounce
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_changesCtrl.isClosed) _changesCtrl.add(signature);
    });
  }

  void setType(String t) {
    if (_type == t) return;
    _type = t;

    // se trocou tipo e saiu de transfer, zera CPF
    if (_type != 'transfer' && _counterpartyCpf.isNotEmpty) {
      _counterpartyCpf = '';
    }

    _emitChange(); // imediato
  }

  void setRange(DateTime? start, DateTime? end) {
    final changed = _start != start || _end != end;
    if (!changed) return;
    _start = start;
    _end = end;
    _emitChange(); // imediato
  }

  void setCounterpartyCpf(String? cpf) {
    final normalized = cpf == null ? '' : CpfInputFormatter.digits(cpf);
    if (_counterpartyCpf == normalized) return;
    _counterpartyCpf = normalized;

    // CPF: muda muito por digitação, então debounced
    _emitChange(debounced: true);
  }

  void clear() {
    _type = '';
    _start = null;
    _end = null;
    _counterpartyCpf = '';

    _emitChange(); // imediato
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _changesCtrl.close();
    super.dispose();
  }
}
