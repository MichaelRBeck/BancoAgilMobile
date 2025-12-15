import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repo;
  SignUp(this.repo);

  Future<void> call({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) {
    return repo.signUp(
      email: email,
      password: password,
      fullName: fullName,
      cpfDigitsOnly: cpfDigitsOnly,
    );
  }
}
