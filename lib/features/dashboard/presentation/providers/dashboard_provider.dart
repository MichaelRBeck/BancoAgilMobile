import 'package:flutter/foundation.dart';

import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/entities/dashboard_summary.dart';

class DashboardProvider extends ChangeNotifier {
  final GetDashboardSummary getDashboardSummary;

  DashboardProvider({required this.getDashboardSummary});

  DashboardSummary _summary = DashboardSummary.empty();
  DashboardSummary get summary => _summary;

  List<Transaction> _items = const [];
  List<Transaction> get items => _items;

  bool _loading = false;
  bool get isLoading => _loading;

  void updateFrom({
    required bool loading,
    required List<Transaction> items,
    required double income,
    required double expense,
    required double transferNet,
    required double balanceDb,
  }) {
    _loading = loading;
    _items = items;

    _summary = getDashboardSummary(
      items: items,
      balanceDb: balanceDb,
      income: income,
      expense: expense,
      transferNet: transferNet,
    );

    notifyListeners();
  }
}
