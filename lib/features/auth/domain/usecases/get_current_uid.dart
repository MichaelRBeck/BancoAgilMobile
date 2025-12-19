import '../repositories/auth_repository.dart';

class GetCurrentUid {
  final AuthRepository repo;
  GetCurrentUid(this.repo);

  Future<String?> call() => repo.currentUid();
}
