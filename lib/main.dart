import 'package:bancoagil/features/transactions/data/cache/transactions_cache_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import 'firebase_options.dart';
import 'core/utils/formatters.dart';
import 'theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/transactions/data/cache/transaction_cache_model.dart';

import 'pages/login_page.dart';
import 'pages/main_shell.dart';

// -------------------------
// AUTH (Clean)
// -------------------------
import 'features/auth/data/datasources/firebase_auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/observe_auth_uid.dart';
import 'features/auth/domain/usecases/get_current_uid.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// -------------------------
// USER / PROFILE
// -------------------------
import 'features/user/data/datasources/user_datasource.dart';
import 'features/user/data/datasources/user_firestore_datasource.dart';
import 'features/user/data/repositories/user_repository_impl.dart';
import 'features/user/domain/repositories/user_repository.dart';
import 'features/user/domain/usecases/get_profile.dart';
import 'features/user/domain/usecases/observe_profile.dart';
import 'features/user/domain/usecases/update_user_profile.dart';
import 'features/user/presentation/providers/user_provider.dart';

// -------------------------
// TRANSACTIONS
// -------------------------
import 'features/transactions/data/datasources/transactions_datasource.dart';
import 'features/transactions/data/datasources/transactions_firestore_datasource.dart';
import 'features/transactions/data/repositories/transactions_repository_impl.dart';
import 'features/transactions/domain/repositories/transactions_repository.dart';
import 'features/transactions/domain/usecases/get_transactions_page.dart';
import 'features/transactions/domain/usecases/delete_transaction.dart';
import 'features/transactions/domain/usecases/calc_totals.dart';
import 'features/transactions/presentation/providers/transactions_filters_provider.dart';
import 'features/transactions/presentation/providers/transactions_provider.dart';

// -------------------------
// FORMS
// -------------------------
import 'features/transactions/domain/usecases/create_transaction.dart';
import 'features/transactions/domain/usecases/update_transaction.dart';
import 'features/transactions/domain/usecases/create_transfer.dart';
import 'features/transactions/domain/usecases/update_transfer_notes.dart';
import 'features/transactions/domain/usecases/execute_transfer.dart';
import 'features/transactions/presentation/providers/transaction_form_provider.dart';
import 'features/transactions/presentation/providers/transfer_form_provider.dart';

// -------------------------
// DASHBOARD / ANALYTICS
// -------------------------
import 'features/dashboard/domain/repositories/analytics_repository.dart';
import 'features/dashboard/data/repositories/analytics_repository_impl.dart';
import 'features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionCacheModelAdapter());
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
        // Core singletons
        // -------------------------
        Provider<fs.FirebaseFirestore>(
          create: (_) => fs.FirebaseFirestore.instance,
        ),
        Provider<fb.FirebaseAuth>(create: (_) => fb.FirebaseAuth.instance),

        // -------------------------
        // Auth (Clean)
        // -------------------------
        Provider<FirebaseAuthDataSource>(
          create: (ctx) => FirebaseAuthDataSource(ctx.read<fb.FirebaseAuth>()),
        ),
        Provider<AuthRepository>(
          create: (ctx) =>
              AuthRepositoryImpl(ctx.read<FirebaseAuthDataSource>()),
        ),
        Provider<ObserveAuthUid>(
          create: (ctx) => ObserveAuthUid(ctx.read<AuthRepository>()),
        ),
        Provider<GetCurrentUid>(
          create: (ctx) => GetCurrentUid(ctx.read<AuthRepository>()),
        ),
        Provider<SignIn>(create: (ctx) => SignIn(ctx.read<AuthRepository>())),
        Provider<SignUp>(create: (ctx) => SignUp(ctx.read<AuthRepository>())),
        Provider<SignOut>(create: (ctx) => SignOut(ctx.read<AuthRepository>())),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) {
            final p = AuthProvider(
              observeAuthUid: ctx.read<ObserveAuthUid>(),
              getCurrentUid: ctx.read<GetCurrentUid>(),
              signInUc: ctx.read<SignIn>(),
              signUpUc: ctx.read<SignUp>(),
              signOutUc: ctx.read<SignOut>(),
            );
            p.init();
            return p;
          },
        ),

        // -------------------------
        // User/Profile
        // -------------------------
        Provider<UserDataSource>(
          create: (ctx) =>
              UserFirestoreDataSource(ctx.read<fs.FirebaseFirestore>()),
        ),
        Provider<UserRepository>(
          create: (ctx) => UserRepositoryImpl(ctx.read<UserDataSource>()),
        ),
        Provider<GetProfile>(
          create: (ctx) => GetProfile(ctx.read<UserRepository>()),
        ),
        Provider<ObserveProfile>(
          create: (ctx) => ObserveProfile(ctx.read<UserRepository>()),
        ),
        Provider<UpdateUserProfile>(
          create: (ctx) => UpdateUserProfile(ctx.read<UserRepository>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (ctx) => UserProvider(
            getProfile: ctx.read<GetProfile>(),
            observeProfile: ctx.read<ObserveProfile>(),
            updateUserProfile: ctx.read<UpdateUserProfile>(),
          ),
          update: (_, auth, up) => up!..apply(auth.uid),
        ),

        // -------------------------
        // Filters (Transactions)
        // -------------------------
        ChangeNotifierProvider(create: (_) => TransactionsFiltersProvider()),

        // -------------------------
        // Transactions Cache (Hive)
        // -------------------------
        Provider<TransactionsCacheDataSource>(
          create: (_) => TransactionsCacheDataSource(),
        ),

        Provider<TransactionsDataSource>(
          create: (ctx) =>
              TransactionsFirestoreDataSource(ctx.read<fs.FirebaseFirestore>()),
        ),

        Provider<TransactionsRepository>(
          create: (ctx) => TransactionsRepositoryImpl(
            ctx.read<TransactionsDataSource>(),
            ctx.read<TransactionsCacheDataSource>(),
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
            tp.apply(auth.uid, filters);
            return tp;
          },
        ),

        // -------------------------
        // Transfer orchestration (usecase)
        // -------------------------
        Provider<ExecuteTransfer>(
          create: (ctx) => ExecuteTransfer(
            firestore: ctx.read<fs.FirebaseFirestore>(),
            txRepo: ctx.read<TransactionsRepository>(),
          ),
        ),

        // -------------------------
        // Transactions Form usecases + providers
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
          create: (ctx) => CreateTransfer(ctx.read<ExecuteTransfer>()),
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

        ChangeNotifierProvider(
          create: (ctx) => TransferFormProvider(
            executeTransfer: ctx.read<ExecuteTransfer>(),
          ),
        ),

        // -------------------------
        // Dashboard / Analytics
        // -------------------------
        Provider<AnalyticsRepository>(create: (_) => AnalyticsRepositoryImpl()),
        Provider<GetDashboardSummary>(
          create: (ctx) => GetDashboardSummary(ctx.read<AnalyticsRepository>()),
        ),

        ChangeNotifierProxyProvider3<
          TransactionsProvider,
          UserProvider,
          GetDashboardSummary,
          DashboardProvider
        >(
          create: (ctx) => DashboardProvider(
            getDashboardSummary: ctx.read<GetDashboardSummary>(),
          ),
          update: (_, tp, up, uc, dp) {
            dp ??= DashboardProvider(getDashboardSummary: uc);

            final items = tp.items;
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

    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.uid == null) {
      return const LoginPage();
    }
    return const MainShell();
  }
}
