import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';

class ProfileProvider extends ChangeNotifier {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;

  ProfileProvider({required this.getProfile, required this.updateProfile});

  bool loading = false;
  bool saving = false;
  String? error;

  UserProfile? profile;

  Future<void> load(String uid) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await getProfile(uid: uid);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    required String uid,
    required String fullName,
    required String cpfDigits,
  }) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
      await updateProfile(uid: uid, fullName: fullName, cpfDigits: cpfDigits);
      profile = profile?.copyWith(fullName: fullName, cpfDigits: cpfDigits);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
