// lib/services/analytics.dart
import '../models/transaction.dart';

class AnalyticsService {
  static DateTime monthKey(DateTime d) => DateTime(d.year, d.month);

  /// Soma por mês filtrando por tipo (ex.: 'income', 'expense', 'transfer').
  /// Se `type` for vazio, soma todos.
  static Map<DateTime, double> sumByMonth(
    List<TransactionModel> items,
    String type,
  ) {
    final map = <DateTime, double>{};
    for (final t in items) {
      if (type.isNotEmpty && (t.type) != type) continue;
      final k = monthKey(t.date);
      final v = (t.amount).toDouble();
      map[k] = (map[k] ?? 0) + v;
    }
    return map;
  }

  /// Consolida em 3 buckets fixos: Receitas, Despesas, Transferências.
  /// - Detecta por `type` preferencialmente: 'income', 'expense', 'transfer'
  ///   (aceita alguns aliases comuns).
  /// - Fallback por sinal do valor quando o tipo não é reconhecido.
  /// - Transferências somadas por valor absoluto.
  static Map<String, double> buildCats3(List<TransactionModel> txs) {
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
      final rawType = (t.type).toString();
      final v = (t.amount).toDouble();
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
      if (v >= 0)
        receitas += absV;
      else
        despesas += absV;
    }

    return {
      'Receitas': receitas,
      'Despesas': despesas,
      'Transferências': transfer,
    };
  }
}
