import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/observe_profile.dart';
import '../../domain/usecases/update_user_profile.dart';

class UserProvider extends ChangeNotifier {
  final GetProfile getProfile;
  final ObserveProfile observeProfile;
  final UpdateUserProfile updateUserProfile;

  UserProvider({
    required this.getProfile,
    required this.observeProfile,
    required this.updateUserProfile,
  });

  UserProfile? _user;
  UserProfile? get user => _user;

  bool _loading = false;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<UserProfile>? _sub;
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
      _user = await getProfile(uid: uid);

      _sub = observeProfile(uid: uid).listen((u) {
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

  Future<void> updateProfile({
    required String fullName,
    required String cpfDigits,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await updateUserProfile(
        uid: uid,
        fullName: fullName,
        cpfDigits: cpfDigits,
      );
      // stream atualiza sozinho
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
