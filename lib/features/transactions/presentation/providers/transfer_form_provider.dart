import 'package:flutter/foundation.dart';
import '../../domain/usecases/create_transfer.dart';

class TransferFormProvider extends ChangeNotifier {
  final CreateTransfer createTransfer;
  TransferFormProvider({required this.createTransfer});

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> submit({
    required String destCpf,
    required double amount,
    String? description,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await createTransfer(
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
