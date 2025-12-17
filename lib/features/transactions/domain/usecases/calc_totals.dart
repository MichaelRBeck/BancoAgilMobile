import '../../data/models/transaction_model.dart';

class TotalsResult {
  final double income;
  final double expense;
  final double transferNet;

  const TotalsResult({
    required this.income,
    required this.expense,
    required this.transferNet,
  });
}

class CalcTotals {
  TotalsResult call(List<TransactionModel> items) {
    double income = 0, expense = 0, transferNet = 0;

    for (final t in items) {
      final v = t.amount.toDouble();

      if (t.type == 'income') income += v.abs();
      if (t.type == 'expense') expense += v.abs();

      // Mantém compatível com o que você já fazia (ajuste se sua regra for outra)
      if (t.type == 'transfer') {
        // normalmente transferNet é líquido (depende do sentido); aqui mantemos "0" por padrão
        // se você já calcula isso no provider atual, depois eu replico exatamente.
        transferNet += 0;
      }
    }

    return TotalsResult(
      income: income,
      expense: expense,
      transferNet: transferNet,
    );
  }
}
