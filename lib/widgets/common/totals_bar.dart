import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

class TotalsBar extends StatelessWidget {
  final bool loading;
  final double income;
  final double expense;
  final double balance;

  const TotalsBar({
    super.key,
    required this.loading,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final color = balance >= 0 ? Colors.green : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: loading
            ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tile('Receitas', money(income)),
                  _tile('Despesas', money(expense)),
                  _tile('Saldo', money(balance), valueColor: color),
                ],
              ),
      ),
    );
  }

  Widget _tile(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
