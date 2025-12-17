import 'package:intl/intl.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  static final DateFormat _ym = DateFormat('yyyy-MM');

  @override
  Map<String, double> sumByMonth(List<TransactionModel> items, String type) {
    final map = <String, double>{};

    for (final t in items) {
      if (t.type != type) continue;
      final key = _ym.format(t.date);
      map[key] = (map[key] ?? 0) + t.amount.toDouble();
    }

    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  Map<String, double> buildCats3(List<TransactionModel> txs) {
    double receitas = 0, despesas = 0, transfer = 0;

    bool isIncome(String s) {
      final x = s.trim().toLowerCase();
      return {
        'income',
        'depósito',
        'deposito',
        'credito',
        'crédito',
        'receita',
      }.contains(x);
    }

    bool isExpense(String s) {
      final x = s.trim().toLowerCase();
      return {
        'expense',
        'saque',
        'withdraw',
        'debito',
        'débito',
        'despesa',
      }.contains(x);
    }

    bool isTransfer(String s) {
      final x = s.trim().toLowerCase();
      return {'transfer', 'transferência', 'transferencia', 'pix'}.contains(x);
    }

    for (final t in txs) {
      final rawType = t.type.toString();
      final v = t.amount.toDouble();
      final absV = v.abs();

      if (isTransfer(rawType)) {
        transfer += absV;
        continue;
      }
      if (isIncome(rawType)) {
        receitas += absV;
        continue;
      }
      if (isExpense(rawType)) {
        despesas += absV;
        continue;
      }

      // fallback por sinal
      if (v >= 0) {
        receitas += absV;
      } else {
        despesas += absV;
      }
    }

    return {
      'Receitas': receitas,
      'Despesas': despesas,
      'Transferências': transfer,
    };
  }
}
