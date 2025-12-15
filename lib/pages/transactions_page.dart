import 'dart:async';

import 'package:bancoagil/utils/animated_routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/sign_out_action.dart';
import '../widgets/common/totals_bar.dart';
import '../features/user/presentation/providers/user_provider.dart';
import '../utils/formatters.dart';
import '../state/filters_provider.dart';
import '../state/transactions_provider.dart';
import 'transaction_form_page.dart';
import '../utils/cpf_input_formatter.dart';

// ✅ Import correto do Model (UI continua usando Model por enquanto)
import '../features/transactions/data/models/transaction_model.dart';

class _Debouncer {
  final Duration delay;
  Timer? _t;
  _Debouncer(this.delay);

  void call(void Function() fn) {
    _t?.cancel();
    _t = Timer(delay, fn);
  }

  void dispose() => _t?.cancel();
}

// Novas opções de ordenação
enum _OrderMode { dataDesc, dataAsc, valorDesc, valorAsc }

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _scroll = ScrollController();
  final _cpfCtrl = TextEditingController();
  final _debounce = _Debouncer(const Duration(milliseconds: 400));

  // Padrão: Data (mais recentes)
  _OrderMode _order = _OrderMode.dataDesc;

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
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _cpfCtrl.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void _onScroll() {
    final tp = context.read<TransactionsProvider>();
    if (!_scroll.hasClients || tp.loading || tp.end) return;
    const threshold = 300;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - threshold) {
      tp.loadMore();
    }
  }

  Future<void> _pickRange() async {
    final filters = context.read<FiltersProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: (filters.start != null && filters.end != null)
          ? DateTimeRange(start: filters.start!, end: filters.end!)
          : null,
    );
    if (picked != null) {
      filters.setRange(
        DateTime(picked.start.year, picked.start.month, picked.start.day),
        DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
    }
  }

  Future<void> _confirmDelete(TransactionModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir transação'),
        content: Text(
          'Tem certeza que deseja excluir "${t.category}" de ${t.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<TransactionsProvider>().delete(t.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transação excluída')));
      }
    }
  }

  // Aplica ordenação local sobre a lista carregada do provider
  List<TransactionModel> _sortedItems(List<TransactionModel> items) {
    final list = [...items];
    switch (_order) {
      case _OrderMode.dataDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _OrderMode.dataAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _OrderMode.valorDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _OrderMode.valorAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  Widget _buildFiltersBar(BuildContext context) {
    final filters = context.watch<FiltersProvider>();

    final labelRange = (filters.start != null && filters.end != null)
        ? '${filters.start!.toLocal().toString().split(' ').first} → ${filters.end!.toLocal().toString().split(' ').first}'
        : 'Período';

    // mantém o campo CPF sincronizado quando tipo = transfer
    if (filters.type != 'transfer' && _cpfCtrl.text.isNotEmpty) {
      _cpfCtrl.text = '';
    }
    if (filters.type == 'transfer') {
      final formatted = CpfInputFormatter.format(filters.counterpartyCpf);
      if (_cpfCtrl.text != formatted) {
        _cpfCtrl.text = formatted;
        _cpfCtrl.selection = TextSelection.collapsed(
          offset: _cpfCtrl.text.length,
        );
      }
    }

    final tipoField = SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: filters.type.isEmpty ? null : filters.type,
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
              controller: _cpfCtrl,
              decoration: InputDecoration(
                labelText: 'CPF do destinatário',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: filters.counterpartyCpf.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpar CPF',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cpfCtrl.clear();
                          filters.setCounterpartyCpf('');
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: const [CpfInputFormatter()],
              onChanged: (v) => _debounce(
                () => filters.setCounterpartyCpf(CpfInputFormatter.digits(v)),
              ),
              onFieldSubmitted: (v) =>
                  filters.setCounterpartyCpf(CpfInputFormatter.digits(v)),
            ),
          )
        : const SizedBox.shrink();

    final periodoBtn = ElevatedButton.icon(
      onPressed: _pickRange,
      icon: const Icon(Icons.date_range),
      label: Text(labelRange),
    );

    final orderField = SizedBox(
      width: 240,
      child: DropdownButtonFormField<_OrderMode>(
        value: _order,
        decoration: const InputDecoration(
          labelText: 'Ordenar por',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(
            value: _OrderMode.dataDesc,
            child: Text('Data (mais recentes)'),
          ),
          DropdownMenuItem(
            value: _OrderMode.dataAsc,
            child: Text('Data (mais antigos)'),
          ),
          DropdownMenuItem(
            value: _OrderMode.valorDesc,
            child: Text('Valor (maior primeiro)'),
          ),
          DropdownMenuItem(
            value: _OrderMode.valorAsc,
            child: Text('Valor (menor primeiro)'),
          ),
        ],
        onChanged: (m) {
          if (m == null) return;
          setState(() => _order = m);
        },
      ),
    );

    final limparBtn = TextButton(
      onPressed: () {
        _cpfCtrl.clear();
        filters.clear();
        setState(() => _order = _OrderMode.dataDesc);
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
                  orderField,
                  const SizedBox(height: 8),
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
                orderField,
                periodoBtn,
                limparBtn,
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TransactionsProvider>();
    final up = context.watch<UserProvider>();

    final items = _sortedItems(tp.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: const [SignOutAction()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            SlideUpRoute(page: const TransactionFormPage()),
          );
          await context.read<TransactionsProvider>().refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFiltersBar(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TotalsBar(
              loading: tp.totalsLoading,
              income: tp.sumIncome,
              expense: tp.sumExpense,
              balance: (up.user?.balance ?? 0).toDouble(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<TransactionsProvider>().refresh(),
              child: ListView.separated(
                controller: _scroll,
                itemCount: items.length + (tp.loading ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  if (i >= items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final t = items[i];
                  final isTransfer = t.type == 'transfer';

                  final name = t.counterpartyName?.trim();
                  final counterNameOrCpf = (name != null && name.isNotEmpty)
                      ? name
                      : (t.counterpartyCpf ?? '');

                  return ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionFormPage(editing: t),
                        ),
                      );
                      await context.read<TransactionsProvider>().refresh();
                    },
                    onLongPress: () => _confirmDelete(t),
                    title: Text(
                      isTransfer
                          ? 'Transferência - $counterNameOrCpf'
                          : '${_cap(t.category)} - ${_displayType(t.type)}',
                    ),
                    subtitle: Text(dmy(t.date)),
                    trailing: Text(money(t.amount)),
                    leading: CircleAvatar(
                      radius: 18,
                      child: Text(
                        isTransfer ? '⇄' : (t.type == 'income' ? '+' : '-'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
