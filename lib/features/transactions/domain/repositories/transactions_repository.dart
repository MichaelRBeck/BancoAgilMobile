import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../entities/transaction.dart';

abstract class TransactionsRepository {
  Future<(List<Transaction>, fs.DocumentSnapshot?)> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    int limit,
    fs.DocumentSnapshot? startAfter,
  });

  Future<void> delete(String id);

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
}
