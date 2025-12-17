import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_datasource.dart';
import '../models/transaction_model.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsDataSource ds;
  TransactionsRepositoryImpl({required this.ds});

  @override
  Future<TransactionsPageResult> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    fs.DocumentSnapshot? startAfter,
    String? counterpartyCpf,
  }) {
    return ds.fetchPage(
      uid: uid,
      type: type,
      start: start,
      end: end,
      limit: limit,
      startAfter: startAfter,
      counterpartyCpf: counterpartyCpf,
    );
  }

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
    return ds.totalsForPeriod(
      uid: uid,
      start: start,
      end: end,
      type: type,
      counterpartyCpf: counterpartyCpf,
    );
  }

  @override
  Future<void> create(TransactionModel model) => ds.create(model);

  @override
  Future<void> update(TransactionModel model) => ds.update(model);

  @override
  Future<void> updateTransferNotes({
    required String id,
    required String notes,
  }) => ds.updateTransferNotes(id: id, notes: notes);

  @override
  Future<void> createTransfer({
    required String destCpf,
    required double amount,
    String? description,
  }) => ds.createTransfer(
    destCpf: destCpf,
    amount: amount,
    description: description,
  );

  @override
  Future<void> delete(String id) => ds.delete(id);
}
