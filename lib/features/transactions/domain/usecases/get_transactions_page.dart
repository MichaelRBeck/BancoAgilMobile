import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../data/datasources/transactions_datasource.dart';
import '../repositories/transactions_repository.dart';

class GetTransactionsPage {
  final TransactionsRepository repo;
  GetTransactionsPage(this.repo);

  Future<TransactionsPageResult> call({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    fs.DocumentSnapshot? startAfter,
    String? counterpartyCpf,
  }) {
    return repo.fetchPage(
      uid: uid,
      type: type,
      start: start,
      end: end,
      limit: limit,
      startAfter: startAfter,
      counterpartyCpf: counterpartyCpf,
    );
  }
}
