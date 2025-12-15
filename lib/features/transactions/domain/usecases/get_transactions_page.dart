import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../entities/transaction.dart';
import '../repositories/transactions_repository.dart';

class GetTransactionsPage {
  final TransactionsRepository repository;
  GetTransactionsPage(this.repository);

  Future<(List<Transaction>, fs.DocumentSnapshot?)> call({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    int limit = 20,
    fs.DocumentSnapshot? startAfter,
  }) {
    return repository.fetchPage(
      uid: uid,
      type: type,
      start: start,
      end: end,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
