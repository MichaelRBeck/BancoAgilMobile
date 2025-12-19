import '../repositories/auth_repository.dart';

class ObserveAuthUid {
  final AuthRepository repo;
  ObserveAuthUid(this.repo);

  Stream<String?> call() => repo.observeUid();
}
