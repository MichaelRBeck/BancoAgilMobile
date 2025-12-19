import 'dart:async';

abstract class AuthRepository {
  Stream<String?> observeUid(); // uid ou null
  Future<String?> currentUid();

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  });
  Future<void> signOut();
}
