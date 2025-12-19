import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/cpf_validator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../providers/transfer_form_provider.dart';

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

  @override
  void dispose() {
    _cpf.dispose();
    _amount.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final destCpf = _cpf.text.trim();
    final amount = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    final desc = _desc.text.trim();

    final fp = context.read<TransferFormProvider>();
    final auth = context.read<AuthProvider>();
    final userProfile = context.read<UserProvider>().user;

    final uid = auth.uid;

    if (uid == null || userProfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuário não autenticado')));
      return;
    }

    try {
      await fp.submit(
        originUid: uid,
        originCpf: userProfile.cpfDigits,
        destCpf: destCpf,
        amount: amount,
        description: desc,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transferência realizada!')));

      Navigator.pop(context, true);
    } catch (_) {
      // erro já tratado no provider
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<TransferFormProvider>();

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
                    if (fp.error != null) ...[
                      Text(
                        fp.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
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
                        onPressed: fp.loading ? null : _submit,
                        icon: const Icon(Icons.send),
                        label: Text(fp.loading ? 'Enviando...' : 'Transferir'),
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
