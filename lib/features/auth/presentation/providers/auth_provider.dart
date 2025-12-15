import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _loading = true;

  AuthProvider() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((u) {
      _user = u;
      _loading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _user != null;

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
