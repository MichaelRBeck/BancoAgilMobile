import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/formatters.dart';
import '../state/transactions_provider.dart';
import '../state/filters_provider.dart';
import '../state/user_provider.dart';
import '../widgets/sign_out_action.dart';
import '../services/analytics.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/pie_chart_widget.dart';
import '../widgets/common/greeting_header.dart';
import '../widgets/common/kpi_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _LegendEntry {
  final String label;
  final Color color;
  const _LegendEntry(this.label, this.color);
}

// ignore: unused_element
class _LegendRow extends StatelessWidget {
  final List<_LegendEntry> entries;
  const _LegendRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: [
        for (final e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(e.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showLine = true;

  String _displayType(String type) {
    switch (type) {
      case 'income':
        return 'Receita';
      case 'expense':
        return 'Despesa';
      case 'transfer':
        return 'Transferência';
      default:
        return _cap(type);
    }
  }

  String _cap(String? s) {
    if (s == null || s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TransactionsProvider>();
    final filters = context.watch<FiltersProvider>();
    final up = context.watch<UserProvider>(); // <- saldo do Firestore aqui

    final items = tp.items;

    // Agregações p/ gráficos
    final incomeByMonth = AnalyticsService.sumByMonth(items, 'income');
    final expenseByMonth = AnalyticsService.sumByMonth(items, 'expense');
    final transferByMonth = AnalyticsService.sumByMonth(items, 'transfer');
    final cats3 = AnalyticsService.buildCats3(items);

    // KPIs de período (analíticos)
    final income = tp.sumIncome;
    final expense = tp.sumExpense;
    final transferNet = tp.sumTransferNet;

    // Saldo real (do Firestore) via provider
    final balanceDb = up.balance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: _showLine ? 'Ver pizza' : 'Ver linha',
            onPressed: () => setState(() => _showLine = !_showLine),
            icon: Icon(_showLine ? Icons.pie_chart : Icons.show_chart),
          ),
          const SignOutAction(),
        ],
      ),
      body: tp.loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GreetingHeader(),
                  const SizedBox(height: 12),

                  // KPIs
                  KpiCard(
                    title: 'Saldo em conta',
                    value: balanceDb,
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                  ),
                  KpiCard(
                    title: 'Receitas (período)',
                    value: income,
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  KpiCard(
                    title: 'Despesas (período)',
                    value: expense,
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                  KpiCard(
                    title: 'Transferências líquidas (período)',
                    value: transferNet,
                    icon: Icons.sync_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 12),

                  // Gráficos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Visão por mês',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment(
                                    value: true,
                                    icon: Icon(Icons.show_chart),
                                    label: Text('Linha'),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    icon: Icon(Icons.pie_chart),
                                    label: Text('Pizza'),
                                  ),
                                ],
                                selected: {_showLine},
                                onSelectionChanged: (s) =>
                                    setState(() => _showLine = s.first),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          SizedBox(
                            height: 350,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _showLine
                                  ? KeyedSubtree(
                                      key: const ValueKey('line_chart'),
                                      child: LineChartView(
                                        items: items,
                                        maxDays: 90,
                                        pxPerDay: 16,
                                      ),
                                    )
                                  : KeyedSubtree(
                                      key: const ValueKey('pie_chart'),
                                      child: PieChart3View(
                                        cats3: cats3,
                                        filterType: filters.type,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Transações recentes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transações recentes',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Nenhuma transação no período.'),
                            )
                          else
                            ...items.take(3).map((t) {
                              final isTransfer = t.type == 'transfer';
                              final counterNameOrCpf =
                                  (t.counterpartyName != null &&
                                      t.counterpartyName!.trim().isNotEmpty)
                                  ? t.counterpartyName!
                                  : (t.counterpartyCpf ?? '');

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  isTransfer
                                      ? 'Transferência - $counterNameOrCpf'
                                      : '${_cap(t.category)} - ${_displayType(t.type)}',
                                ),
                                subtitle: Text(dmy(t.date)),
                                trailing: Text(money(t.amount)),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
