/*
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../features/auth/domain/usecases/observe_auth_uid.dart';
import '../features/auth/domain/usecases/get_current_uid.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/auth/domain/usecases/sign_up.dart';

class AuthProvider extends ChangeNotifier {
  final ObserveAuthUid observeAuthUid;
  final GetCurrentUid getCurrentUid;
  final SignIn signInUseCase;
  final SignUp signUpUseCase;
  final SignOut signOutUseCase;

  String? _uid;
  bool _loading = true;
  StreamSubscription<String?>? _sub;

  AuthProvider({
    required this.observeAuthUid,
    required this.getCurrentUid,
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
  }) {
    _init();
  }

  Future<void> _init() async {
    _uid = await getCurrentUid();
    _sub?.cancel();
    _sub = observeAuthUid().listen((uid) {
      _uid = uid;
      _loading = false;
      notifyListeners();
    });
  }

  String? get uid => _uid;
  bool get isLoading => _loading;
  bool get isLoggedIn => _uid != null;

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
*/
