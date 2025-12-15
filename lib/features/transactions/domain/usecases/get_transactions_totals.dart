import '../repositories/transactions_repository.dart';

class GetTransactionsTotals {
  final TransactionsRepository repository;
  GetTransactionsTotals(this.repository);

  Future<
    ({
      double income,
      double expense,
      double transferIn,
      double transferOut,
      double transferNet,
    })
  >
  call({
    required String uid,
    DateTime? start,
    DateTime? end,
    String? type,
    String? counterpartyCpf,
  }) {
    return repository.totalsForPeriod(
      uid: uid,
      start: start,
      end: end,
      type: type,
      counterpartyCpf: counterpartyCpf,
    );
  }
}
