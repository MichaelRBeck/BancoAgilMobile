import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/transactions/presentation/providers/transactions_filters_provider.dart';
import '../../../../core/utils/cpf_input_formatter.dart';

class TransactionsFiltersBar extends StatefulWidget {
  final VoidCallback onPickRange;
  final TextEditingController cpfController;
  final void Function() onClear;

  const TransactionsFiltersBar({
    super.key,
    required this.onPickRange,
    required this.cpfController,
    required this.onClear,
  });

  @override
  State<TransactionsFiltersBar> createState() => _TransactionsFiltersBarState();
}

class _TransactionsFiltersBarState extends State<TransactionsFiltersBar> {
  @override
  Widget build(BuildContext context) {
    final filters = context.watch<TransactionsFiltersProvider>();

    final labelRange = (filters.start != null && filters.end != null)
        ? '${filters.start!.toLocal().toString().split(' ').first} → ${filters.end!.toLocal().toString().split(' ').first}'
        : 'Período';

    // mantém o campo CPF sincronizado quando tipo = transfer
    if (filters.type != 'transfer' && widget.cpfController.text.isNotEmpty) {
      widget.cpfController.text = '';
    }
    if (filters.type == 'transfer') {
      final formatted = CpfInputFormatter.format(filters.counterpartyCpf);
      if (widget.cpfController.text != formatted) {
        widget.cpfController.text = formatted;
        widget.cpfController.selection = TextSelection.collapsed(
          offset: widget.cpfController.text.length,
        );
      }
    }

    final tipoField = SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        initialValue: filters.type.isEmpty ? null : filters.type,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 'income', child: Text('Receita')),
          DropdownMenuItem(value: 'expense', child: Text('Despesa')),
          DropdownMenuItem(value: 'transfer', child: Text('Transferência')),
        ],
        onChanged: (v) => filters.setType(v ?? ''),
      ),
    );

    final Widget cpfField = (filters.type == 'transfer')
        ? SizedBox(
            width: 240,
            child: TextFormField(
              controller: widget.cpfController,
              decoration: InputDecoration(
                labelText: 'CPF do destinatário',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: filters.counterpartyCpf.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpar CPF',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.cpfController.clear();
                          filters.setCounterpartyCpf('');
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: const [CpfInputFormatter()],
              onChanged: (v) =>
                  filters.setCounterpartyCpf(CpfInputFormatter.digits(v)),
              onFieldSubmitted: (v) =>
                  filters.setCounterpartyCpf(CpfInputFormatter.digits(v)),
            ),
          )
        : const SizedBox.shrink();

    final periodoBtn = ElevatedButton.icon(
      onPressed: widget.onPickRange,
      icon: const Icon(Icons.date_range),
      label: Text(labelRange),
    );

    final limparBtn = TextButton(
      onPressed: () {
        widget.cpfController.clear();
        widget.onClear();
      },
      child: const Text('Limpar'),
    );

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tipoField,
                  const SizedBox(height: 8),
                  if (filters.type == 'transfer') ...[
                    cpfField,
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(child: periodoBtn),
                      const SizedBox(width: 8),
                      limparBtn,
                    ],
                  ),
                ],
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                tipoField,
                if (filters.type == 'transfer') cpfField,
                periodoBtn,
                limparBtn,
              ],
            );
          },
        ),
      ),
    );
  }
}
