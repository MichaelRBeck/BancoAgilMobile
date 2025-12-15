import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/get_user.dart';
import '../../domain/usecases/observe_user.dart';
import '../../domain/usecases/update_user_profile.dart';

class UserProvider extends ChangeNotifier {
  final GetUser getUser;
  final ObserveUser observeUser;
  final UpdateUserProfile updateUserProfile;

  UserProvider({
    required this.getUser,
    required this.observeUser,
    required this.updateUserProfile,
  });

  AppUser? _user;
  AppUser? get user => _user;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription? _sub;
  String? _uid;

  Future<void> apply(String? uid) async {
    if (uid == _uid) return;

    _uid = uid;
    _user = null;
    _error = null;

    await _sub?.cancel();
    _sub = null;

    if (uid == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      // 1) carga inicial (rápida)
      _user = await getUser(uid);

      // 2) stream para manter atualizado
      _sub = observeUser(uid).listen((u) {
        _user = u;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? cpf}) async {
    final uid = _uid;
    if (uid == null) return;

    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await updateUserProfile(uid, name: name, cpf: cpf);
      // stream atualiza sozinho; opcional: otimista
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
