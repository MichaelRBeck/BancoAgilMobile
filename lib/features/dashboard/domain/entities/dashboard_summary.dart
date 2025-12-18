import 'package:flutter/foundation.dart';

@immutable
class DashboardSummary {
  final double balanceDb;
  final double income;
  final double expense;
  final double transferNet;

  final Map<String, double> incomeByMonth;
  final Map<String, double> expenseByMonth;
  final Map<String, double> transferByMonth;

  final Map<String, double> cats3;

  const DashboardSummary({
    required this.balanceDb,
    required this.income,
    required this.expense,
    required this.transferNet,
    required this.incomeByMonth,
    required this.expenseByMonth,
    required this.transferByMonth,
    required this.cats3,
  });

  factory DashboardSummary.empty() => const DashboardSummary(
    balanceDb: 0,
    income: 0,
    expense: 0,
    transferNet: 0,
    incomeByMonth: {},
    expenseByMonth: {},
    transferByMonth: {},
    cats3: {},
  );
}
