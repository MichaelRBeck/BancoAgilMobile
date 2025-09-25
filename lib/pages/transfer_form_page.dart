import 'package:flutter/material.dart';
import '../services/transfer_local_service.dart';
import '../utils/cpf_validator.dart';

class TransferFormPage extends StatefulWidget {
  const TransferFormPage({super.key});

  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  final _form = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cpf.dispose();
    _amount.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!_form.currentState!.validate()) return;

      final destCpf = _cpf.text.trim();
      final amount = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
      final desc = _desc.text.trim();

      final service = TransferLocalService();
      await service.createTransfer(
        destCpf: destCpf,
        amount: amount,
        description: desc,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transferência realizada!')));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova transferência')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: _cpf,
                      decoration: const InputDecoration(
                        labelText: 'CPF do destinatário',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe o CPF';
                        if (!CpfValidator.isValid(v)) return 'CPF inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amount,
                      decoration: const InputDecoration(labelText: 'Valor'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final x =
                            double.tryParse((v ?? '').replaceAll(',', '.')) ??
                            0;
                        if (x <= 0) return 'Informe um valor maior que zero';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: const Icon(Icons.send),
                        label: Text(_loading ? 'Enviando...' : 'Transferir'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
