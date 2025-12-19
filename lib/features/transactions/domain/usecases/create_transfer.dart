import 'execute_transfer.dart';

class CreateTransfer {
  final ExecuteTransfer exec;
  CreateTransfer(this.exec);

  Future<void> call({
    required String originUid,
    required String originCpf,
    required String destCpf,
    required double amount,
    String? description,
  }) {
    return exec(
      originUid: originUid,
      originCpf: originCpf,
      destCpf: destCpf,
      amount: amount,
      description: description,
    );
  }
}
