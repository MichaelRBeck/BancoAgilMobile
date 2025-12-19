import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/cpf_input_formatter.dart';
import '../../../../widgets/common/receipt_attachment.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

import '../../domain/entities/transaction.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transactions_provider.dart';

class TransactionFormPage extends StatefulWidget {
  final Transaction? editing;
  const TransactionFormPage({super.key, this.editing});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _form = GlobalKey<FormState>();

  String _type = 'expense';
  String _category = '';
  double? _amount;
  DateTime _date = DateTime.now();
  String _notes = '';

  final _destCpfCtrl = TextEditingController();

  bool get _isEditing => widget.editing != null;
  bool get _isEditingTransfer =>
      _isEditing && widget.editing!.type == 'transfer';

  @override
  void initState() {
    super.initState();

    final t = widget.editing;
    if (t != null) {
      _type = t.type;
      _category = t.category;
      _amount = t.amount;
      _date = t.date;
      _notes = (t.notes ?? '').trim();

      if (t.type == 'transfer') {
        final cpf = (t.counterpartyCpf ?? t.destCpf ?? '');
        _destCpfCtrl.text = CpfInputFormatter.format(cpf);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TransactionFormProvider>().setInitialReceipt(
          receiptBase64: t.receiptBase64,
          contentType: t.contentType,
        );
      });
    }
  }

  @override
  void dispose() {
    _destCpfCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_type == 'transfer') {
      final cpf = _destCpfCtrl.text.trim();
      if (cpf.isEmpty) return 'Informe o CPF do destinatário';
      if (_amount == null || _amount! <= 0) return 'Informe um valor positivo';
      return null;
    } else {
      if (_amount == null || _amount! <= 0) return 'Informe um valor positivo';
      if (_category.trim().isEmpty) return 'Informe a categoria';
      return null;
    }
  }

  Future<void> _deleteEditing() async {
    final t = widget.editing;
    if (t == null) return;

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

    if (ok != true) return;

    await context.read<TransactionsProvider>().delete(t.id);

    if (!mounted) return;
    Navigator.pop(context); // volta da tela de edição

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transação excluída')));
  }

  Future<void> _save() async {
    final msg = _validate();
    if (msg != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final auth = context.read<AuthProvider>();
    final profile = context.read<UserProvider>().user;

    final uid = auth.uid;

    if (uid == null || profile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuário não autenticado.')));
      return;
    }

    final fp = context.read<TransactionFormProvider>();

    try {
      await fp.save(
        uid: uid,
        originCpf: profile.cpfDigits,
        isEditing: _isEditing,
        editing: widget.editing,
        type: _type,
        category: _category.trim(),
        amount: _amount!,
        date: _date,
        notes: _notes.trim(),
        destCpf: _destCpfCtrl.text.trim(),
      );

      if (!mounted) return;

      await context.read<TransactionsProvider>().refresh();

      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'transfer'
                ? (_isEditing
                      ? 'Transferência atualizada!'
                      : 'Transferência realizada!')
                : (_isEditing ? 'Transação atualizada!' : 'Transação criada!'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fp.error ?? 'Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<TransactionFormProvider>();
    final editing = _isEditing;
    final isTransfer = _type == 'transfer';
    final canDelete = editing && !isTransfer;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar Transação' : 'Nova Transação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Receita')),
                  DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                  DropdownMenuItem(
                    value: 'transfer',
                    child: Text('Transferência'),
                  ),
                ],
                onChanged: _isEditingTransfer
                    ? null
                    : (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 12),

              if (isTransfer) ...[
                TextFormField(
                  controller: _destCpfCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CPF do destinatário',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CpfInputFormatter()],
                  enabled: !_isEditingTransfer,
                ),
                const SizedBox(height: 12),
              ],

              if (!isTransfer) ...[
                TextFormField(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  onChanged: (v) => _category = v,
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                initialValue: _amount?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Valor'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) =>
                    _amount = double.tryParse(v.replaceAll(',', '.')),
                enabled: !_isEditingTransfer,
              ),
              const SizedBox(height: 12),

              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
                onChanged: (v) => _notes = v,
              ),
              const SizedBox(height: 12),

              if (!isTransfer) ...[
                ReceiptAttachment(
                  receiptBase64: fp.receiptBase64,
                  contentType: fp.contentType,
                  onPick: fp.pickReceipt,
                  onRemove: fp.removeReceipt,
                ),
                const SizedBox(height: 12),
              ],

              if (fp.error != null) ...[
                const SizedBox(height: 8),
                Text(fp.error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fp.saving ? null : _save,
                  child: Text(
                    fp.saving
                        ? (editing ? 'Atualizando...' : 'Salvando...')
                        : (editing ? 'Salvar alterações' : 'Salvar'),
                  ),
                ),
              ),

              if (canDelete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: fp.saving ? null : _deleteEditing,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Excluir transação'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
