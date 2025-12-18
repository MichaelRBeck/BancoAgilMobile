import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../services/transfer_local_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transactions_cursor.dart';
import '../../domain/entities/transactions_page_result.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_datasource.dart';
import '../dto/transactions_cursor_dto.dart';
import '../models/transaction_model.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsDataSource ds;
  final TransferLocalService transferService;

  TransactionsRepositoryImpl({required this.ds, required this.transferService});

  TransactionsCursorDto? _toDto(TransactionsCursor? c) {
    if (c == null) return null;
    return TransactionsCursorDto(
      date: fs.Timestamp.fromDate(c.date),
      docId: c.docId,
    );
  }

  TransactionsCursor? _toDomain(TransactionsCursorDto? c) {
    if (c == null) return null;
    return TransactionsCursor(date: c.date.toDate(), docId: c.docId);
  }

  @override
  Future<TransactionsPageResult> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    TransactionsCursor? startAfter,
    String? counterpartyCpf,
  }) async {
    final result = await ds.fetchPage(
      uid: uid,
      type: type,
      start: start,
      end: end,
      limit: limit,
      startAfter: _toDto(startAfter),
      counterpartyCpf: counterpartyCpf,
    );

    return TransactionsPageResult(
      items: result.items.map((m) => m.toEntity()).toList(),
      nextCursor: _toDomain(result.nextCursor),
      hasMore: result.hasMore,
    );
  }

  @override
  Future<void> create(Transaction entity) {
    return ds.create(TransactionModel.fromEntity(entity));
  }

  @override
  Future<void> update(Transaction entity) {
    return ds.update(TransactionModel.fromEntity(entity));
  }

  @override
  Future<void> delete(String id) => ds.delete(id);

  @override
  Future<void> createTransfer({
    required String destCpf,
    required double amount,
    String? description,
  }) {
    return transferService.createTransfer(
      destCpf: destCpf,
      amount: amount,
      description: description,
    );
  }

  @override
  Future<void> updateTransferNotes({
    required String id,
    required String notes,
  }) {
    return ds.updateTransferNotes(id: id, notes: notes);
  }
}
