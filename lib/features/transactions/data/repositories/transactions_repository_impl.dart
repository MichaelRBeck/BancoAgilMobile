import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_firestore_datasource.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsFirestoreDatasource ds;
  TransactionsRepositoryImpl(this.ds);

  @override
  Future<(List<Transaction>, fs.DocumentSnapshot?)> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    int limit = 20,
    fs.DocumentSnapshot? startAfter,
  }) => ds.fetchPage(
    uid: uid,
    type: type,
    start: start,
    end: end,
    limit: limit,
    startAfter: startAfter,
  );

  @override
  Future<void> delete(String id) => ds.delete(id);

  @override
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
  }) {
    throw UnimplementedError(); // entra na Fase T2
  }
}
