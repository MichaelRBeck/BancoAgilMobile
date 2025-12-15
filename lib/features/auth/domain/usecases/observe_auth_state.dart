import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthState {
  final AuthRepository repo;
  ObserveAuthState(this.repo);

  Stream<User?> call() => repo.authStateChanges();
}
