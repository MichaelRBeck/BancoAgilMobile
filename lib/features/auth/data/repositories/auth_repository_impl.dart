import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firestore_user_datasource.dart';
import '../mappers/auth_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth auth;
  final FirestoreUserDataSource userDs;

  AuthRepositoryImpl({required this.auth, required this.userDs});

  String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');
  String _emailLower(String s) => s.trim().toLowerCase();

  @override
  Stream<AuthUser?> authStateChanges() {
    return auth.authStateChanges().map(
      (u) => u == null ? null : AuthUserMapper.fromFirebase(u),
    );
  }

  @override
  AuthUser? currentUser() {
    final u = auth.currentUser;
    return u == null ? null : AuthUserMapper.fromFirebase(u);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final cred = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ✅ opcional (recomendado): “cura” usuários antigos/incompletos
    final u = cred.user;
    if (u != null) {
      final displayName = (u.displayName ?? '').trim();
      await userDs.createUserDocIfMissing(
        uid: u.uid,
        emailLower: _emailLower(u.email ?? email),
        fullName: displayName.isEmpty ? 'Usuário' : displayName,
        cpfDigitsOnly:
            '', // se não tiver no login, deixa vazio (backfill depois)
      );
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cpfDigitsOnly,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) return;

    final name = fullName.trim();
    final cpf = _digits(cpfDigitsOnly);

    // 1) Atualiza displayName do Auth (opcional, mas legal)
    if (name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }

    // 2) ✅ Seed completo do Firestore (users/{uid})
    await userDs.createUserDocIfMissing(
      uid: user.uid,
      emailLower: _emailLower(email),
      fullName: name,
      cpfDigitsOnly: cpf,
    );

    // 3) ✅ Índice de CPF (cpfIndex/{cpf})
    if (cpf.isNotEmpty) {
      await userDs.upsertCpfIndex(
        uid: user.uid,
        fullName: name,
        cpfDigitsOnly: cpf,
      );
    }
  }

  @override
  Future<void> signOut() => auth.signOut();
}
