import '../entities/transaction.dart';

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
  TotalsResult call(List<Transaction> items) {
    double income = 0;
    double expense = 0;
    double transferNet = 0;

    for (final t in items) {
      switch (t.type) {
        case 'income':
          income += t.amount;
          break;

        case 'expense':
          expense += t.amount;
          break;

        case 'transfer':
          // net = entrada - saída já vem refletido no entity
          transferNet += t.amount;
          break;
      }
    }

    return TotalsResult(
      income: income,
      expense: expense,
      transferNet: transferNet,
    );
  }
}
