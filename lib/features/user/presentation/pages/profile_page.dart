import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/cpf_input_formatter.dart';
import '../../../../core/utils/cpf_validator.dart';
import '../providers/user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cpf = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final up = context.read<UserProvider>();
      final u = up.user;
      if (u != null) {
        _name.text = u.fullName;
        _cpf.text = CpfInputFormatter.format(u.cpfDigits);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final up = context.read<UserProvider>();

    await up.updateProfile(
      fullName: _name.text.trim(),
      cpfDigits: CpfValidator.onlyDigits(_cpf.text),
    );

    if (!mounted) return;

    if (up.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(up.error!)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: up.isLoading && up.user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (up.error != null) ...[
                      Text(
                        up.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Informe seu nome completo'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cpf,
                      decoration: const InputDecoration(labelText: 'CPF'),
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CpfInputFormatter()],
                      validator: (v) => CpfValidator.isValid(v ?? '')
                          ? null
                          : 'CPF inválido (11 dígitos)',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: up.isLoading ? null : _save,
                      child: Text(up.isLoading ? 'Salvando...' : 'Salvar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
