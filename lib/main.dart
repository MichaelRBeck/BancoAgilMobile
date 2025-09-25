import 'package:bancoagil/state/user_provider.dart';
import 'package:bancoagil/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'utils/formatters.dart';
import 'package:provider/provider.dart';
import 'state/auth_provider.dart';
import 'state/filters_provider.dart';
import 'state/transactions_provider.dart';
import 'services/transactions_service.dart';
import 'pages/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initFormatters(); // pt_BR para intl
  } catch (e) {
    runApp(BootErrorApp(error: e));
    return;
  }

  runApp(const MyApp());
}

class BootErrorApp extends StatelessWidget {
  final Object error;
  const BootErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Falha ao iniciar Firebase')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao inicializar o Firebase:\n\n$error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Autenticação
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Filtros globais
        ChangeNotifierProvider(create: (_) => FiltersProvider()),

        // Service puro
        Provider(create: (_) => TransactionsService()),

        // TransactionsProvider reage a Auth + Filters + Service
        ChangeNotifierProxyProvider3<
          AuthProvider,
          FiltersProvider,
          TransactionsService,
          TransactionsProvider
        >(
          create: (ctx) =>
              TransactionsProvider(service: ctx.read<TransactionsService>()),
          update: (_, auth, filters, service, tp) {
            tp ??= TransactionsProvider(service: service);
            // aplica quando auth e/ou filtros mudarem
            tp.apply(auth.user?.uid, filters);
            return tp;
          },
        ),

        // UserProvider escuta users/{uid} para saldo/nome/CPF em tempo real
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, up) => up!..apply(auth.user?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'Banco Ágil',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme, // apenas um tema
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isLoggedIn) {
      return const LoginPage();
    }
    return const MainShell();
  }
}
