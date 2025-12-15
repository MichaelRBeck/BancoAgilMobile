import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_user_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource authDs;
  final FirestoreUserDataSource userDs;

  AuthRepositoryImpl({required this.authDs, required this.userDs});

  @override
  Stream<User?> authStateChanges() => authDs.authStateChanges();

  @override
  User? currentUser() => authDs.currentUser();

  @override
  Future<void> signIn({required String email, required String password}) {
    return authDs.signIn(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) async {
    final cred = await authDs.signUp(email: email, password: password);
    final uid = cred.user!.uid;

    await userDs.createUserDocIfMissing(
      uid: uid,
      emailLower: email.toLowerCase(),
      fullName: fullName,
      cpfDigitsOnly: cpfDigitsOnly,
    );

    await userDs.upsertCpfIndex(
      uid: uid,
      fullName: fullName,
      cpfDigitsOnly: cpfDigitsOnly,
    );
  }

  @override
  Future<void> signOut() => authDs.signOut();
}
