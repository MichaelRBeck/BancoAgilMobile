import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/cpf_input_formatter.dart';
import '../../../../core/utils/cpf_utils.dart';

import '../../../user/presentation/providers/user_provider.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';

import '../providers/transactions_provider.dart';
import '../providers/transaction_form_provider.dart';
import '../providers/transfer_form_provider.dart';

import '../../../../widgets/common/receipt_attachment.dart';

class TransactionFormPage extends StatefulWidget {
  final Transaction? editing;
  const TransactionFormPage({super.key, this.editing});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _form = GlobalKey<FormState>();

  // transfer fields
  final _destCpfCtrl = TextEditingController();

  // common fields
  String _type = 'income';
  String _category = '';
  double? _amount;
  String _notes = '';

  bool _submitting = false;
  String? _localError;

  bool get _isEditing => widget.editing != null;
  bool get _isTransfer => _type == 'transfer';
  bool get _editingTransfer => _isEditing && widget.editing?.type == 'transfer';
  bool get _canDelete => _isEditing && !_isTransfer;

  @override
  void initState() {
    super.initState();

    final e = widget.editing;
    if (e != null) {
      _type = e.type;
      _category = e.category;
      _amount = e.amount;
      _notes = e.notes ?? '';

      if (e.type == 'transfer') {
        // Preferir counterpartyCpf (destino do ponto de vista do origin),
        // senão fallback para destCpf.
        final cpfDigits = (e.counterpartyCpf?.trim().isNotEmpty ?? false)
            ? (e.counterpartyCpf ?? '')
            : (e.destCpf ?? '');
        _destCpfCtrl.text = CpfInputFormatter.format(cpfDigits);
      }
    }
  }

  @override
  void dispose() {
    _destCpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) return;
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _localError = null;
    });

    try {
      final up = context.read<UserProvider>().user;
      final uid = (up?.uid ?? '').trim();
      final cpf = (up?.cpfDigits ?? '').trim();

      if (uid.isEmpty) {
        throw Exception('Usuário não autenticado.');
      }

      if (_isTransfer) {
        final destCpfDigits = CpfUtils.digits(_destCpfCtrl.text);

        await context.read<TransferFormProvider>().submit(
          originUid: uid,
          originCpf: cpf,
          destCpf: destCpfDigits,
          amount: _amount ?? 0,
          description: _notes.trim().isEmpty ? null : _notes.trim(),
        );
      } else {
        final fp = context.read<TransactionFormProvider>(); // só para anexos
        final now = DateTime.now();

        final entity = Transaction(
          id: widget.editing?.id ?? '',
          userId: uid,
          type: _type,
          category: _category.trim().isEmpty ? _type : _category.trim(),
          amount: _amount ?? 0,
          date: widget.editing?.date ?? now,
          notes: _notes,
          receiptBase64: fp.receiptBase64,
          contentType: fp.contentType,
          createdAt: widget.editing?.createdAt ?? now,
          updatedAt: now,
        );

        if (_isEditing) {
          await context.read<UpdateTransaction>()(entity);
        } else {
          await context.read<CreateTransaction>()(entity);
        }
      }

      if (!mounted) return;

      await context.read<TransactionsProvider>().refresh();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _localError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteEditing() async {
    if (_submitting) return;
    final editing = widget.editing;
    if (editing == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir transação'),
        content: const Text('Tem certeza que deseja excluir esta transação?'),
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

    setState(() {
      _submitting = true;
      _localError = null;
    });

    try {
      final up = context.read<UserProvider>().user;
      final uid = (up?.uid ?? '').trim();
      if (uid.isEmpty) throw Exception('Usuário não autenticado.');

      await context.read<DeleteTransaction>()(uid: uid, id: editing.id);

      if (!mounted) return;

      await context.read<TransactionsProvider>().refresh();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _localError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<TransactionFormProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Transação' : 'Nova Transação'),
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
                onChanged: _editingTransfer
                    ? null
                    : (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 12),

              if (_isTransfer) ...[
                TextFormField(
                  controller: _destCpfCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CPF do destinatário',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [CpfInputFormatter()],
                  enabled: !_editingTransfer,
                  validator: (v) {
                    final d = CpfUtils.digits(v ?? '');
                    if (d.length != 11) return 'CPF inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (!_isTransfer) ...[
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
                enabled: !_editingTransfer, // não editar valor em transfer
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Informe um valor válido';
                  return null;
                },
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

              // anexos só para receita/despesa
              if (!_isTransfer) ...[
                ReceiptAttachment(
                  receiptBase64: fp.receiptBase64,
                  contentType: fp.contentType,
                  onPick: fp.pickReceipt,
                  onRemove: fp.removeReceipt,
                ),
                const SizedBox(height: 12),
              ],

              if (_localError != null) ...[
                const SizedBox(height: 8),
                Text(_localError!, style: const TextStyle(color: Colors.red)),
              ],

              if (fp.error != null && _localError == null) ...[
                const SizedBox(height: 8),
                Text(fp.error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _save,
                  child: Text(
                    _submitting
                        ? (_isEditing ? 'Atualizando...' : 'Salvando...')
                        : (_isEditing ? 'Salvar alterações' : 'Salvar'),
                  ),
                ),
              ),

              if (_canDelete) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : _deleteEditing,
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
