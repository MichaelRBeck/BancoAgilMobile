import '../../../transactions/domain/entities/transaction.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/analytics_repository.dart';

class GetDashboardSummary {
  final AnalyticsRepository analyticsRepo;
  GetDashboardSummary(this.analyticsRepo);

  DashboardSummary call({
    required List<Transaction> items,
    required double balanceDb,
    required double income,
    required double expense,
    required double transferNet,
  }) {
    final incomeByMonth = analyticsRepo.sumByMonth(items, 'income');
    final expenseByMonth = analyticsRepo.sumByMonth(items, 'expense');
    final transferByMonth = analyticsRepo.sumByMonth(items, 'transfer');
    final cats3 = analyticsRepo.buildCats3(items);

    return DashboardSummary(
      balanceDb: balanceDb,
      income: income,
      expense: expense,
      transferNet: transferNet,
      incomeByMonth: incomeByMonth,
      expenseByMonth: expenseByMonth,
      transferByMonth: transferByMonth,
      cats3: cats3,
    );
  }
}
