import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ✅ use o Model (compatível com a UI atual)
import '../../../../transactions/data/models/transaction_model.dart';

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class LineChartView extends StatefulWidget {
  /// Transações já filtradas pelo período atual.
  final List<TransactionModel> items;

  /// Limite de dias para manter performance (default: 90).
  final int maxDays;

  /// Pixels por dia (controla “zoom” horizontal).
  final double pxPerDay;

  const LineChartView({
    super.key,
    required this.items,
    this.maxDays = 90,
    this.pxPerDay = 16.0,
  });

  @override
  State<LineChartView> createState() => _LineChartViewState();
}

class _LineChartViewState extends State<LineChartView> {
  final _chartKey = GlobalKey();
  OverlayEntry? _tooltipEntry;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  double _nz(double? v) {
    if (v == null || v.isNaN || v.isInfinite) return 0;
    return v;
  }

  void _add(Map<DateTime, double> dest, DateTime k, double v) {
    final dk = _dayKey(k);
    dest[dk] = (dest[dk] ?? 0) + v;
  }

  List<DateTime> _dayRange(DateTime start, DateTime end) {
    final List<DateTime> out = [];
    var cur = _dayKey(start);
    final last = _dayKey(end);
    while (!cur.isAfter(last)) {
      out.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }

  String _labelForIdx(int i, List<DateTime> seq) {
    if (i < 0 || i >= seq.length) return '';
    final d = seq[i];
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
  }

  // “Nice numbers” para step agradável (1, 2, 2.5, 5 × 10^n)
  double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final pow10 = math.pow(10, (math.log(raw) / math.ln10).floor());
    final f = raw / pow10;
    double nf;
    if (f <= 1) {
      nf = 1;
    } else if (f <= 2) {
      nf = 2;
    } else if (f <= 2.5) {
      nf = 2.5;
    } else if (f <= 5) {
      nf = 5;
    } else {
      nf = 10;
    }
    return nf * pow10;
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  void _showTooltip(Offset globalPos, List<LineBarSpot> spots) {
    _hideTooltip();

    String serieName(int idx) {
      switch (idx) {
        case 0:
          return 'Receitas';
        case 1:
          return 'Despesas';
        case 2:
          return 'Transferências';
        default:
          return '';
      }
    }

    final ordered = [...spots]..sort((a, b) => b.y.compareTo(a.y));

    Widget tooltipContent() {
      return Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in ordered)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${serieName(s.barIndex)}: ${s.y.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Usa o OVERLAY RAIZ (sempre acima de tudo)
    final overlay = Overlay.of(context, rootOverlay: true);

    final screenSize = MediaQuery.of(context).size;
    const dx = 12.0;
    const dy = 12.0;

    double left = globalPos.dx + dx;
    double top = globalPos.dy - dy;

    // Mantém dentro da tela
    left = left.clamp(8.0, screenSize.width - 280.0);
    top = top.clamp(8.0, screenSize.height - 140.0);

    _tooltipEntry = OverlayEntry(
      builder: (_) => Positioned(left: left, top: top, child: tooltipContent()),
    );

    overlay.insert(_tooltipEntry!);
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('Sem dados no período.'));
    }

    final incomeByDay = <DateTime, double>{};
    final expenseByDay = <DateTime, double>{};
    final transferByDay = <DateTime, double>{};

    for (final t in widget.items) {
      final k = _dayKey(t.date);
      switch (t.type) {
        case 'income':
          _add(incomeByDay, k, _nz(t.amount));
          break;
        case 'expense':
          _add(expenseByDay, k, _nz(t.amount));
          break;
        case 'transfer':
          _add(transferByDay, k, _nz(t.amount).abs());
          break;
      }
    }

    final allKeys = <DateTime>{
      ...incomeByDay.keys,
      ...expenseByDay.keys,
      ...transferByDay.keys,
    }.toList()..sort();

    if (allKeys.isEmpty) {
      return const Center(child: Text('Sem dados no período.'));
    }

    // Sequência diária contínua + limite performance
    var daySeq = _dayRange(allKeys.first, allKeys.last);
    bool truncated = false;
    if (daySeq.length > widget.maxDays) {
      truncated = true;
      daySeq = daySeq.sublist(daySeq.length - widget.maxDays);
    }

    // Spots
    final spotsIncome = <FlSpot>[];
    final spotsExpense = <FlSpot>[];
    final spotsTransfer = <FlSpot>[];

    for (var i = 0; i < daySeq.length; i++) {
      final d = daySeq[i];
      spotsIncome.add(FlSpot(i.toDouble(), _nz(incomeByDay[d])));
      spotsExpense.add(FlSpot(i.toDouble(), _nz(expenseByDay[d])));
      spotsTransfer.add(FlSpot(i.toDouble(), _nz(transferByDay[d])));
    }

    List<FlSpot> ensureTwo(List<FlSpot> s) {
      if (s.length == 1) {
        final p = s.first;
        return [p, FlSpot(p.x + 1, p.y)];
      }
      return s;
    }

    final income2 = ensureTwo(spotsIncome);
    final expense2 = ensureTwo(spotsExpense);
    final transfer2 = ensureTwo(spotsTransfer);

    // Escala Y bonita
    double yMaxData = 0;
    for (final s in [...income2, ...expense2, ...transfer2]) {
      if (s.y > yMaxData) yMaxData = s.y;
    }
    if (yMaxData <= 0) yMaxData = 1;

    const int targetTicks = 5;
    final rawStep = yMaxData / targetTicks;
    final step = _niceStep(rawStep);
    double niceTop = (yMaxData / step).ceil() * step;
    if ((niceTop - yMaxData) < step * 0.3) {
      niceTop += step;
    }

    const minY = 0.0;
    final maxY = niceTop;

    // Eixo X
    const minX = 0.0;
    final maxX = (daySeq.length > 1) ? (daySeq.length - 1).toDouble() : 1.0;

    // Scroll horizontal
    const double minChartWidth = 600;
    final double chartWidth = math.max(
      minChartWidth,
      daySeq.length * widget.pxPerDay,
    );

    // Intervalo de labels no X
    double tickIntervalX;
    if (daySeq.length <= 14) {
      tickIntervalX = 1;
    } else if (daySeq.length <= 60) {
      tickIntervalX = 3;
    } else {
      tickIntervalX = 7;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (truncated)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Mostrando os últimos ${widget.maxDays} dias para melhor desempenho.',
                style: TextStyle(
                  fontSize: 12,
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          SizedBox(
            height: 260,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                key: _chartKey,
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(show: true, horizontalInterval: step),
                    borderData: FlBorderData(show: true),

                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches:
                          false, // desliga tooltip interno do fl_chart
                      touchTooltipData: LineTouchTooltipData(
                        // esses campos ficam sem efeito com handleBuiltInTouches=false,
                        // mas mantemos para compatibilidade futura
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        tooltipBorderRadius: BorderRadius.circular(6),
                      ),
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.lineBarSpots == null) {
                          _hideTooltip();
                          return;
                        }

                        // Posição global do toque (a partir da posição local do chart)
                        final box =
                            _chartKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (box == null) {
                          _hideTooltip();
                          return;
                        }

                        final local = event.localPosition;
                        // Converte para coordenadas globais
                        final global = box.localToGlobal(local!);

                        // Mostra overlay com os spots tocados
                        final spots = response.lineBarSpots!;
                        if (spots.isNotEmpty) {
                          _showTooltip(global, spots);
                        } else {
                          _hideTooltip();
                        }

                        // Esconde ao terminar o gesto
                        if (event is FlLongPressEnd ||
                            event is FlPanEndEvent ||
                            event is FlTapUpEvent) {
                          _hideTooltip();
                        }
                      },
                    ),

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: step,
                          getTitlesWidget: (value, meta) {
                            if ((value % step).abs() > 1e-6) {
                              return const SizedBox.shrink();
                            }
                            final txt = value >= 1000
                                ? value.toStringAsFixed(0)
                                : value.toStringAsFixed(2);
                            return Text(
                              txt,
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: tickIntervalX,
                          getTitlesWidget: (value, meta) {
                            final i = value.round();
                            final label = _labelForIdx(i, daySeq);
                            if (label.isEmpty) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              space: 8,
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: income2,
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.green,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: expense2,
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.red,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: transfer2,
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.blue,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendItem(color: Colors.green, text: 'Receitas'),
              SizedBox(width: 16),
              _LegendItem(color: Colors.red, text: 'Despesas'),
              SizedBox(width: 16),
              _LegendItem(color: Colors.blue, text: 'Transferências'),
            ],
          ),
        ],
      ),
    );
  }
}
