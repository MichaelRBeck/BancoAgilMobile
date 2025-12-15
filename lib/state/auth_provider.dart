import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/domain/usecases/observe_auth_state.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';

class AuthProvider extends ChangeNotifier {
  final ObserveAuthState observeAuthState;
  final SignIn signInUseCase;
  final SignUp signUpUseCase;
  final SignOut signOutUseCase;

  User? _user;
  bool _loading = true;
  StreamSubscription<User?>? _sub;

  AuthProvider({
    required this.observeAuthState,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
  }) {
    _sub = observeAuthState().listen((u) {
      _user = u;
      _loading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _user != null;

  Future<void> signIn({required String email, required String password}) {
    return signInUseCase(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) {
    return signUpUseCase(
      email: email,
      password: password,
      fullName: fullName,
      cpfDigitsOnly: cpfDigitsOnly,
    );
  }

  Future<void> signOut() => signOutUseCase();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
