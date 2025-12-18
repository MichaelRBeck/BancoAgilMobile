import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthState {
  final AuthRepository repo;
  ObserveAuthState(this.repo);

  Stream<AuthUser?> call() => repo.authStateChanges();
}
