import '../../../transactions/domain/entities/transaction.dart';

abstract class AnalyticsRepository {
  Map<String, double> sumByMonth(List<Transaction> items, String type);
  Map<String, double> buildCats3(List<Transaction> items);
}
