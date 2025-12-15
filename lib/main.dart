import 'package:bancoagil/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'utils/formatters.dart';
import 'pages/main_shell.dart';

import 'state/auth_provider.dart';
import 'state/filters_provider.dart';
import 'state/transactions_provider.dart';
import 'services/transactions_service.dart';

// Auth Clean
import 'features/auth/data/datasources/firebase_auth_datasource.dart';
import 'features/auth/data/datasources/firestore_user_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/observe_auth_state.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';

// User/Profile Clean (ajuste os paths conforme sua estrutura)
import 'features/user/data/datasources/firestore_user_profile_datasource.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/domain/repositories/user_repository.dart';
import 'features/user/domain/usecases/get_user.dart';
import 'features/user/domain/usecases/observe_user.dart';
import 'features/user/domain/usecases/update_user_profile.dart';
import 'features/user/presentation/providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
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
        // -------------------------
        // Auth (Clean Architecture)
        // -------------------------
        Provider<FirebaseAuthDataSource>(
          create: (_) => FirebaseAuthDataSource(),
        ),
        Provider<FirestoreUserDataSource>(
          create: (_) => FirestoreUserDataSource(),
        ),
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            authDs: ctx.read<FirebaseAuthDataSource>(),
            userDs: ctx.read<FirestoreUserDataSource>(),
          ),
        ),
        Provider<ObserveAuthState>(
          create: (ctx) => ObserveAuthState(ctx.read<AuthRepository>()),
        ),
        Provider<SignIn>(create: (ctx) => SignIn(ctx.read<AuthRepository>())),
        Provider<SignUp>(create: (ctx) => SignUp(ctx.read<AuthRepository>())),
        Provider<SignOut>(create: (ctx) => SignOut(ctx.read<AuthRepository>())),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            observeAuthState: ctx.read<ObserveAuthState>(),
            signInUseCase: ctx.read<SignIn>(),
            signUpUseCase: ctx.read<SignUp>(),
            signOutUseCase: ctx.read<SignOut>(),
          ),
        ),

        // -------------------------
        // Filtros globais
        // -------------------------
        ChangeNotifierProvider<FiltersProvider>(
          create: (_) => FiltersProvider(),
        ),

        // -------------------------
        // Transactions (já funcionando)
        // -------------------------
        Provider<TransactionsService>(create: (_) => TransactionsService()),
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
            tp.apply(auth.user?.uid, filters);
            return tp;
          },
        ),

        // -------------------------
        // User/Profile (Clean Architecture)
        // -------------------------
        Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),

        Provider<FirestoreUserProfileDataSource>(
          create: (ctx) =>
              FirestoreUserProfileDataSourceImpl(ctx.read<FirebaseFirestore>()),
        ),

        Provider<UserRepository>(
          create: (ctx) => UserRepositoryImpl(
            ds: ctx.read<FirestoreUserProfileDataSource>(),
          ),
        ),

        Provider<GetUser>(create: (ctx) => GetUser(ctx.read<UserRepository>())),
        Provider<ObserveUser>(
          create: (ctx) => ObserveUser(ctx.read<UserRepository>()),
        ),
        Provider<UpdateUserProfile>(
          create: (ctx) => UpdateUserProfile(ctx.read<UserRepository>()),
        ),

        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (ctx) => UserProvider(
            getUser: ctx.read<GetUser>(),
            observeUser: ctx.read<ObserveUser>(),
            updateUserProfile: ctx.read<UpdateUserProfile>(),
          ),
          update: (_, auth, up) => up!..apply(auth.user?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'Banco Ágil',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
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
