import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/observe_auth_uid.dart';
import '../../domain/usecases/get_current_uid.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_out.dart';

class AuthProvider extends ChangeNotifier {
  final ObserveAuthUid observeAuthUid;
  final GetCurrentUid getCurrentUid;
  final SignIn signInUc;
  final SignUp signUpUc;
  final SignOut signOutUc;

  AuthProvider({
    required this.observeAuthUid,
    required this.getCurrentUid,
    required this.signInUc,
    required this.signUpUc,
    required this.signOutUc,
  });

  String? _uid;
  String? get uid => _uid;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<String?>? _sub;

  Future<void> init() async {
    _uid = await getCurrentUid();
    _sub?.cancel();
    _sub = observeAuthUid().listen((uid) {
      _uid = uid;
      notifyListeners();
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await signInUc(email: email, password: password);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await signUpUc(
        email: email,
        password: password,
        fullName: fullName,
        cpfDigitsOnly: cpfDigitsOnly,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await signOutUc();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
