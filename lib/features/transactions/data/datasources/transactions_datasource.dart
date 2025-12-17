import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../../data/models/transaction_model.dart';

class TransactionsPageResult {
  final List<TransactionModel> items;
  final fs.DocumentSnapshot? nextCursor;
  final bool hasMore;

  const TransactionsPageResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

abstract class TransactionsDataSource {
  Future<TransactionsPageResult> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    fs.DocumentSnapshot? startAfter,
    String? counterpartyCpf,
  });

  Future<
    ({
      double income,
      double expense,
      double transferIn,
      double transferOut,
      double transferNet,
    })
  >
  totalsForPeriod({
    required String uid,
    DateTime? start,
    DateTime? end,
    String? type,
    String? counterpartyCpf,
  });

  Future<void> create(TransactionModel model);
  Future<void> update(TransactionModel model);
  Future<void> updateTransferNotes({required String id, required String notes});

  Future<void> createTransfer({
    required String destCpf,
    required double amount,
    String? description,
  });

  Future<void> delete(String id);
}
