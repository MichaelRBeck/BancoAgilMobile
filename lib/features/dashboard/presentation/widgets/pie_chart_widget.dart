// lib/widgets/charts/pie_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PieChart3View extends StatelessWidget {
  final Map<String, double>
  cats3; // chaves esperadas: Receitas, Despesas, Transferências
  final String filterType;

  const PieChart3View({
    super.key,
    required this.cats3,
    required this.filterType,
  });

  Color _colorForLabel(String label) {
    switch (label) {
      case 'Receitas':
        return const Color(0xFF10B981); // verde
      case 'Despesas':
        return const Color(0xFFEF4444); // vermelho
      case 'Transferências':
      default:
        return const Color(0xFF3B82F6); // azul
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = ['Receitas', 'Despesas', 'Transferências'];
    final ordered = [for (final k in order) MapEntry(k, (cats3[k] ?? 0))];
    final entries = ordered.where((e) => e.value > 0).toList();

    if (entries.isEmpty) {
      return const Center(child: Text('Sem dados no período.'));
    }

    final total = entries.fold<double>(0, (acc, e) => acc + e.value);
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Padding(
      key: const ValueKey('pie'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  for (final e in entries)
                    PieChartSectionData(
                      value: e.value,
                      title: total > 0
                          ? '${((e.value / total) * 100).toStringAsFixed(0)}%'
                          : '',
                      radius: 60,
                      color: _colorForLabel(e.key),
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              for (final e in entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _colorForLabel(e.key),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.key}: ${currency.format(e.value)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Baseado em ${filterType.isEmpty ? "todas as transações" : filterType}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
