import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../state/transactions_provider.dart';
import '../services/transactions_service.dart';
import '../services/transfer_local_service.dart';
import '../utils/cpf_input_formatter.dart';
import '../widgets/common/receipt_attachment.dart';

import '../features/transactions/data/models/transaction_model.dart';

class TransactionFormPage extends StatefulWidget {
  final TransactionModel? editing; // se vier preenchido, estamos editando
  const TransactionFormPage({super.key, this.editing});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _form = GlobalKey<FormState>();
  final _service = TransactionsService();

  String _type = 'expense';
  String _category = '';
  double? _amount;
  DateTime _date = DateTime.now();
  String? _notes;
  bool _saving = false;

  // Recibo (base64)
  String? _receiptBase64;
  String? _contentType; // "image/jpeg"

  // TRANSFER: CPF destinatário
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
      _notes = t.notes;
      _receiptBase64 = t.receiptBase64;
      _contentType = t.contentType;

      if (t.type == 'transfer') {
        final cpf = (t.counterpartyCpf ?? t.destCpf ?? '');
        _destCpfCtrl.text = CpfInputFormatter.format(cpf);
      }
    }
  }

  @override
  void dispose() {
    _destCpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        File(x.path).absolute.path,
        minWidth: 1080,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      if (compressedBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível comprimir a imagem.')),
        );
        return;
      }

      if (compressedBytes.length > 900 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recibo muito grande. Tente outra imagem/foto menor.',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _receiptBase64 = base64Encode(compressedBytes);
        _contentType = 'image/jpeg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
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

  Future<double> _getUserBalance(String uid) async {
    final snap = await fs.FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = snap.data();
    if (data == null) return 0.0;
    final b = data['balance'];
    if (b is int) return b.toDouble();
    if (b is double) return b;
    if (b is num) return b.toDouble();
    return 0.0;
  }

  Future<void> _incUserBalance(String uid, double delta) async {
    if (delta == 0) return;
    await fs.FirebaseFirestore.instance.collection('users').doc(uid).update({
      'balance': fs.FieldValue.increment(delta),
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

  double _deltaFor(String type, double amount) {
    if (type == 'income') return amount;
    if (type == 'expense') return -amount;
    return 0.0; // transfer não mexe aqui (serviço próprio trata)
  }

  Future<void> _save() async {
    final msg = _validate();
    if (msg != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    try {
      if (_type == 'transfer') {
        if (_isEditing) {
          final old = widget.editing!;
          await fs.FirebaseFirestore.instance
              .collection('transactions')
              .doc(old.id)
              .update({
                'notes': _notes ?? '',
                'updatedAt': fs.FieldValue.serverTimestamp(),
              });

          if (!mounted) return;
          await context.read<TransactionsProvider>().refresh();
          Navigator.pop(context);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transferência atualizada!')),
          );
          return;
        }

        await TransferLocalService().createTransfer(
          destCpf: _destCpfCtrl.text.trim(),
          amount: _amount!,
          description: _notes,
        );

        if (!mounted) return;
        await context.read<TransactionsProvider>().refresh();
        Navigator.pop(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transferência realizada!')),
        );
        return;
      }

      // ✅ Validação genérica de saldo projetado (previne ficar < 0)
      {
        final curr = await _getUserBalance(uid);
        final oldDelta = _isEditing
            ? _deltaFor(widget.editing!.type, widget.editing!.amount)
            : 0.0;
        final newDelta = _deltaFor(_type, _amount ?? 0);
        final projected = curr - oldDelta + newDelta;

        if (projected < 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Saldo insuficiente. Saldo atual: ${curr.toStringAsFixed(2)}. '
                'Após esta alteração ficaria: ${projected.toStringAsFixed(2)}.',
              ),
            ),
          );
          setState(() => _saving = false);
          return;
        }
      }

      if (widget.editing == null) {
        final model = TransactionModel(
          id: 'new',
          userId: uid,
          type: _type,
          category: _category,
          amount: _amount!,
          date: _date,
          notes: _notes,
          receiptBase64: _receiptBase64,
          contentType: _receiptBase64 != null ? _contentType : null,
          createdAt: now,
          updatedAt: now,
        );
        await _service.add(model);

        // 🔄 Atualiza saldo: income(+), expense(-)
        await _incUserBalance(uid, _deltaFor(_type, _amount!));

        if (!mounted) return;
        await context.read<TransactionsProvider>().refresh();
        Navigator.pop(context);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transação criada!')));
      } else {
        final old = widget.editing!;
        final edited = TransactionModel(
          id: old.id,
          userId: old.userId,
          type: _type,
          category: _category,
          amount: _amount!,
          date: _date,
          notes: _notes,
          receiptBase64: _receiptBase64,
          contentType: _receiptBase64 != null ? _contentType : null,
          createdAt: old.createdAt,
          updatedAt: now,
        );
        await _service.update(edited);

        // 🔄 Ajusta saldo considerando a troca de tipo/valor
        final oldDelta = _deltaFor(old.type, old.amount);
        final newDelta = _deltaFor(_type, _amount!);
        final diff = newDelta - oldDelta;
        await _incUserBalance(uid, diff);

        if (!mounted) return;
        await context.read<TransactionsProvider>().refresh();
        Navigator.pop(context);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transação atualizada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _isEditing;
    final isTransfer = _type == 'transfer';

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
                value: _type,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'income', child: Text('Receita')),
                  DropdownMenuItem(value: 'expense', child: Text('Despesa')),
                  DropdownMenuItem(
                    value: 'transfer',
                    child: Text('Transferência'),
                  ),
                ],
                onChanged: _isEditingTransfer
                    ? null
                    : (String? v) => setState(() => _type = v!),
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
                  onChanged: (v) => _category = v.trim(),
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
                initialValue: _notes ?? '',
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
                onChanged: (v) => _notes = v.trim(),
              ),
              const SizedBox(height: 12),

              if (!isTransfer) ...[
                ReceiptAttachment(
                  receiptBase64: _receiptBase64,
                  contentType: _contentType,
                  onPick: _pickReceipt,
                  onRemove: () => setState(() {
                    _receiptBase64 = null;
                    _contentType = null;
                  }),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving
                        ? (editing ? 'Atualizando...' : 'Salvando...')
                        : (editing ? 'Salvar alterações' : 'Salvar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
