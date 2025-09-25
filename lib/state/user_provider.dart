import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? _uid;
  StreamSubscription<DocumentSnapshot>? _sub;

  bool _loading = false;
  String _fullName = '';
  String _cpf = '';
  double _balance = 0.0;

  bool get loading => _loading;
  String get fullName => _fullName;
  String get cpf => _cpf;
  double get balance => _balance;

  /// Chame isto quando o UID mudar (login/logout).
  void apply(String? uid) {
    if (_uid == uid) return;
    _uid = uid;

    _sub?.cancel();
    _fullName = '';
    _cpf = '';
    _balance = 0.0;

    if (_uid == null) {
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    final docRef = FirebaseFirestore.instance.collection('users').doc(_uid);
    _sub = docRef.snapshots().listen(
      (snap) {
        if (!snap.exists) {
          _fullName = '';
          _cpf = '';
          _balance = 0.0;
        } else {
          final data = snap.data() ?? {};
          _fullName = (data['fullName'] ?? '').toString();
          _cpf = (data['cpf'] ?? '').toString();
          _balance = (data['balance'] ?? 0).toDouble();
        }
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
