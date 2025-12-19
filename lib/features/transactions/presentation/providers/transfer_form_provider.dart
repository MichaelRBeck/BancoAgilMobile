import 'package:flutter/foundation.dart';

import '../../domain/usecases/execute_transfer.dart';

class TransferFormProvider extends ChangeNotifier {
  final ExecuteTransfer executeTransfer;

  TransferFormProvider({required this.executeTransfer});

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> submit({
    required String originUid,
    required String originCpf,
    required String destCpf,
    required double amount,
    String? description,
    String? destName, // ✅ novo (opcional)
  }) async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await executeTransfer(
        originUid: originUid,
        originCpf: originCpf,
        destCpf: destCpf,
        amount: amount,
        description: description,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
