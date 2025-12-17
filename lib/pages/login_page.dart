import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/cpf_input_formatter.dart';
import '../core/utils/cpf_validator.dart';
import '../state/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  // cadastro
  final _fullName = TextEditingController();
  final _cpf = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/finance.jpg'), context);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _fullName.dispose();
    _cpf.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_form.currentState!.validate()) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final email = _email.text.trim();
      final pass = _pass.text.trim();

      final auth = context.read<AuthProvider>();

      if (_isLogin) {
        await auth.signIn(email: email, password: pass);
      } else {
        final fullName = _fullName.text.trim();
        final cpfInput = _cpf.text.trim();
        final confirm = _confirm.text.trim();

        if (fullName.length < 3) throw Exception('Informe seu nome completo.');
        if (!CpfValidator.isValid(cpfInput)) throw Exception('CPF inválido.');
        if (pass.length < 6) {
          throw Exception('Senha deve ter pelo menos 6 caracteres.');
        }
        if (pass != confirm) throw Exception('As senhas não conferem.');

        await auth.signUp(
          email: email,
          password: pass,
          fullName: fullName,
          cpfDigitsOnly: CpfValidator.onlyDigits(cpfInput),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 420.0;
    const cardPadding = EdgeInsets.all(16);

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Entrar' : 'Criar conta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: cardPadding,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _AuthBranding(isLogin: _isLogin),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _fullName,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 3)
                                  ? 'Informe seu nome completo'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cpf,
                              decoration: const InputDecoration(
                                labelText: 'CPF',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CpfInputFormatter()],
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Informe o CPF';
                                if (!CpfValidator.isValid(v))
                                  return 'CPF inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Informe o email';
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass,
                            decoration: const InputDecoration(
                              labelText: 'Senha',
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.length < 6)
                                return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirm,
                              decoration: const InputDecoration(
                                labelText: 'Confirmar senha',
                              ),
                              obscureText: true,
                              validator: (v) => (v != _pass.text)
                                  ? 'As senhas não conferem'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: Text(
                                _loading
                                    ? 'Enviando...'
                                    : (_isLogin ? 'Entrar' : 'Criar conta'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin
                                  ? 'Não tem conta? Criar conta'
                                  : 'Já tem conta? Entrar',
                            ),
                          ),
                        ],
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

class _AuthBranding extends StatelessWidget {
  final bool isLogin;
  const _AuthBranding({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final appName = RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(
          context,
        ).style.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
        children: [
          const TextSpan(text: 'Banco'),
          TextSpan(
            text: 'Ágil',
            style: TextStyle(color: primary),
          ),
        ],
      ),
    );

    final imgPath = isLogin
        ? 'assets/finance.jpg'
        : 'assets/finance_register.jpg';

    return Column(
      children: [
        appName,
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            key: ValueKey(imgPath),
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imgPath,
                fit: BoxFit.cover,
                cacheWidth: 900,
                errorBuilder: (context, error, stack) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.image_not_supported,
                        size: 28,
                        color: Colors.black45,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Imagem não encontrada',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
