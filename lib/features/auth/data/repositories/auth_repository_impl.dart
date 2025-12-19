import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource ds;
  AuthRepositoryImpl(this.ds);

  @override
  Stream<String?> observeUid() => ds.observeUid();

  @override
  Future<String?> currentUid() async => ds.currentUid();

  @override
  Future<void> signIn({required String email, required String password}) {
    return ds.signIn(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) {
    return ds.signUp(
      email: email,
      password: password,
      fullName: fullName,
      cpfDigitsOnly: cpfDigitsOnly,
    );
  }

  @override
  Future<void> signOut() => ds.signOut();
}
