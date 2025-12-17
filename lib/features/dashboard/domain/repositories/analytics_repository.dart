import '../../../transactions/data/models/transaction_model.dart';

abstract class AnalyticsRepository {
  Map<String, double> sumByMonth(List<TransactionModel> items, String type);

  /// Deve retornar SEMPRE:
  /// { 'Receitas': x, 'Despesas': y, 'Transferências': z }
  Map<String, double> buildCats3(List<TransactionModel> items);
}
