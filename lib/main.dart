import 'package:bancoagil/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'core/utils/formatters.dart';
import 'pages/main_shell.dart';

import 'state/auth_provider.dart';
import 'state/filters_provider.dart';
import 'state/transactions_provider.dart';
import 'services/transactions_service.dart';
import 'services/transfer_local_service.dart';

// Auth
import 'features/auth/data/datasources/firebase_auth_datasource.dart';
import 'features/auth/data/datasources/firestore_user_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/observe_auth_state.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';

// User/Profile
import 'features/user/data/datasources/firestore_user_profile_datasource.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/domain/repositories/user_repository.dart';
import 'features/user/domain/usecases/get_user.dart';
import 'features/user/domain/usecases/observe_user.dart';
import 'features/user/domain/usecases/update_user_profile.dart';
import 'features/user/presentation/providers/user_provider.dart';

// Transactions
import 'features/transactions/data/datasources/transactions_datasource.dart';
import 'features/transactions/data/datasources/transactions_datasource_impl.dart';
import 'features/transactions/data/repositories/transactions_repository_impl.dart';
import 'features/transactions/domain/repositories/transactions_repository.dart';
import 'features/transactions/domain/usecases/get_transactions_page.dart';
import 'features/transactions/domain/usecases/delete_transaction.dart';
import 'features/transactions/domain/usecases/calc_totals.dart';
import 'features/transactions/data/models/transaction_model.dart';

// Form usecases + provider
import 'features/transactions/domain/usecases/create_transaction.dart';
import 'features/transactions/domain/usecases/update_transaction.dart';
import 'features/transactions/domain/usecases/create_transfer.dart';
import 'features/transactions/domain/usecases/update_transfer_notes.dart';
import 'features/transactions/presentation/providers/transaction_form_provider.dart';

// Dashboard / Analytics
import 'features/dashboard/domain/repositories/analytics_repository_impl.dart';
import 'features/dashboard/domain/repositories/analytics_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initFormatters();
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
        // Core / Firebase singletons
        // -------------------------
        Provider<FirebaseFirestore>(create: (_) => FirebaseFirestore.instance),

        // -------------------------
        // Auth (Clean)
        // -------------------------
        Provider(create: (_) => FirebaseAuthDataSource()),
        Provider(create: (_) => FirestoreUserDataSource()),
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            authDs: ctx.read<FirebaseAuthDataSource>(),
            userDs: ctx.read<FirestoreUserDataSource>(),
          ),
        ),
        Provider(create: (ctx) => ObserveAuthState(ctx.read<AuthRepository>())),
        Provider(create: (ctx) => SignIn(ctx.read<AuthRepository>())),
        Provider(create: (ctx) => SignUp(ctx.read<AuthRepository>())),
        Provider(create: (ctx) => SignOut(ctx.read<AuthRepository>())),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(
            observeAuthState: ctx.read<ObserveAuthState>(),
            signInUseCase: ctx.read<SignIn>(),
            signUpUseCase: ctx.read<SignUp>(),
            signOutUseCase: ctx.read<SignOut>(),
          ),
        ),

        // -------------------------
        // Filters (Transactions feature)
        // -------------------------
        ChangeNotifierProvider(create: (_) => TransactionsFiltersProvider()),

        // -------------------------
        // Transactions (Clean)
        // -------------------------
        Provider<TransactionsService>(create: (_) => TransactionsService()),
        Provider<TransferLocalService>(create: (_) => TransferLocalService()),

        Provider<TransactionsDataSource>(
          create: (ctx) => TransactionsDataSourceImpl(
            ctx.read<TransactionsService>(),
            transferService: ctx.read<TransferLocalService>(),
            db: ctx.read<FirebaseFirestore>(),
          ),
        ),

        Provider<TransactionsRepository>(
          create: (ctx) => TransactionsRepositoryImpl(
            ds: ctx.read<TransactionsDataSource>(),
          ),
        ),

        Provider<GetTransactionsPage>(
          create: (ctx) =>
              GetTransactionsPage(ctx.read<TransactionsRepository>()),
        ),
        Provider<DeleteTransaction>(
          create: (ctx) =>
              DeleteTransaction(ctx.read<TransactionsRepository>()),
        ),
        Provider<CalcTotals>(create: (_) => CalcTotals()),

        ChangeNotifierProxyProvider2<
          AuthProvider,
          TransactionsFiltersProvider,
          TransactionsProvider
        >(
          create: (ctx) => TransactionsProvider(
            getPage: ctx.read<GetTransactionsPage>(),
            deleteTx: ctx.read<DeleteTransaction>(),
            calcTotals: ctx.read<CalcTotals>(),
          ),
          update: (ctx, auth, filters, tp) {
            tp ??= TransactionsProvider(
              getPage: ctx.read<GetTransactionsPage>(),
              deleteTx: ctx.read<DeleteTransaction>(),
              calcTotals: ctx.read<CalcTotals>(),
            );
            tp.apply(auth.user?.uid, filters);
            return tp;
          },
        ),

        // -------------------------
        // Transactions Form (Clean)
        // -------------------------
        Provider<CreateTransaction>(
          create: (ctx) =>
              CreateTransaction(ctx.read<TransactionsRepository>()),
        ),
        Provider<UpdateTransaction>(
          create: (ctx) =>
              UpdateTransaction(ctx.read<TransactionsRepository>()),
        ),
        Provider<CreateTransfer>(
          create: (ctx) => CreateTransfer(ctx.read<TransactionsRepository>()),
        ),
        Provider<UpdateTransferNotes>(
          create: (ctx) =>
              UpdateTransferNotes(ctx.read<TransactionsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TransactionFormProvider(
            createTx: ctx.read<CreateTransaction>(),
            updateTx: ctx.read<UpdateTransaction>(),
            createTransfer: ctx.read<CreateTransfer>(),
            updateTransferNotes: ctx.read<UpdateTransferNotes>(),
          ),
        ),

        // -------------------------
        // User/Profile (Clean)
        // -------------------------
        Provider(
          create: (ctx) =>
              FirestoreUserProfileDataSourceImpl(ctx.read<FirebaseFirestore>()),
        ),
        Provider<UserRepository>(
          create: (ctx) => UserRepositoryImpl(
            ds: ctx.read<FirestoreUserProfileDataSource>(),
          ),
        ),
        Provider(create: (ctx) => GetUser(ctx.read())),
        Provider(create: (ctx) => ObserveUser(ctx.read())),
        Provider(create: (ctx) => UpdateUserProfile(ctx.read())),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (ctx) => UserProvider(
            getUser: ctx.read<GetUser>(),
            observeUser: ctx.read<ObserveUser>(),
            updateUserProfile: ctx.read<UpdateUserProfile>(),
          ),
          update: (_, auth, up) => up!..apply(auth.user?.uid),
        ),

        // -------------------------
        // Dashboard / Analytics (Clean)
        // -------------------------
        Provider<AnalyticsRepository>(create: (_) => AnalyticsRepositoryImpl()),
        Provider(
          create: (ctx) => GetDashboardSummary(ctx.read<AnalyticsRepository>()),
        ),
        ChangeNotifierProxyProvider3<
          TransactionsProvider,
          UserProvider,
          GetDashboardSummary,
          DashboardProvider
        >(
          create: (ctx) => DashboardProvider(getDashboardSummary: ctx.read()),
          update: (_, tp, up, uc, dp) {
            dp ??= DashboardProvider(getDashboardSummary: uc);

            final items = tp.items.whereType<TransactionModel>().toList();
            final balanceDb = (up.user?.balance ?? 0).toDouble();

            dp.updateFrom(
              loading: tp.loading,
              items: items,
              income: tp.sumIncome,
              expense: tp.sumExpense,
              transferNet: tp.sumTransferNet,
              balanceDb: balanceDb,
            );

            return dp;
          },
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
