import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/cpf_input_formatter.dart';
import '../../../../core/utils/cpf_validator.dart';
import '../../../../state/auth_provider.dart';
import '../providers/profile_provider.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final uid = context.read<AuthProvider>().user?.uid;
      if (uid == null || uid.isEmpty) return;

      final pp = context.read<ProfileProvider>();
      await pp.load(uid);

      final profile = pp.profile;
      if (profile != null) {
        _name.text = profile.fullName;
        _cpf.text = CpfInputFormatter.format(profile.cpfDigits);
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

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null || uid.isEmpty) return;

    final pp = context.read<ProfileProvider>();

    try {
      await pp.save(
        uid: uid,
        fullName: _name.text.trim(),
        cpfDigits: CpfValidator.onlyDigits(_cpf.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
      Navigator.pop(context, true);
    } catch (_) {
      // erro já aparece em pp.error
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: pp.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pp.error != null) ...[
                      Text(
                        pp.error!,
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
                      onPressed: pp.saving ? null : _save,
                      child: Text(pp.saving ? 'Salvando...' : 'Salvar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
