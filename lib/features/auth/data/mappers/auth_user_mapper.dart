import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/auth_user.dart';

class AuthUserMapper {
  static AuthUser fromFirebase(fb.User u) {
    return AuthUser(uid: u.uid, email: u.email, displayName: u.displayName);
  }
}
