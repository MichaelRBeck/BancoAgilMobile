import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {
  final FirebaseAuth auth;
  FirebaseAuthDataSource(this.auth);

  Stream<String?> observeUid() => auth.authStateChanges().map((u) => u?.uid);

  String? currentUid() => auth.currentUser?.uid;

  Future<void> signIn({required String email, required String password}) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) async {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => auth.signOut();
}
