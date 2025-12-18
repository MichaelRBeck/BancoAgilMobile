import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GreetingHeader extends StatelessWidget {
  final String? firstName;

  const GreetingHeader({super.key, this.firstName});

  String _saudacao() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    final greeting = (firstName == null || firstName!.trim().isEmpty)
        ? '${_saudacao()}!'
        : '${_saudacao()}, ${firstName!.trim()}';

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    toBeginningOfSentenceCase(
                      DateFormat(
                        'MMMM \'de\' y',
                        'pt_BR',
                      ).format(DateTime.now()),
                    )!,
                    style: TextStyle(
                      // ignore: deprecated_member_use
                      color: onPrimary.withOpacity(.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
