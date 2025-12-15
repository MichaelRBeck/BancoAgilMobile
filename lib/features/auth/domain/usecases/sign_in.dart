import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repo;
  SignIn(this.repo);

  Future<void> call({required String email, required String password}) {
    return repo.signIn(email: email, password: password);
  }
}
