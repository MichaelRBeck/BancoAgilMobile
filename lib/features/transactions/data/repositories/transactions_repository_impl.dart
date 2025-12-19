import '../../domain/entities/transaction.dart';
import '../../domain/entities/transactions_cursor.dart';
import '../../domain/entities/transactions_page_result.dart';
import '../../domain/repositories/transactions_repository.dart';

import '../datasources/transactions_datasource.dart';
import '../dto/transactions_cursor_dto.dart';
import '../models/transaction_model.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsDataSource ds;
  TransactionsRepositoryImpl(this.ds);

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
    final page = await ds.fetchPage(
      uid: uid,
      type: type,
      start: start,
      end: end,
      limit: limit,
      startAfter: startAfter == null
          ? null
          : TransactionsCursorDto.fromEntity(startAfter),
      counterpartyCpf: counterpartyCpf,
    );

    return TransactionsPageResult(
      items: page.items.map((m) => m.toEntity()).toList(),
      nextCursor: page.nextCursor?.toEntity(),
      hasMore: page.hasMore,
    );
  }

  @override
  Future<void> create(Transaction entity) {
    return ds.create(
      uid: entity.userId,
      model: TransactionModel.fromEntity(entity),
    );
  }

  @override
  Future<void> update(Transaction entity) {
    return ds.update(
      uid: entity.userId,
      model: TransactionModel.fromEntity(entity),
    );
  }

  @override
  Future<void> delete(String id, {required String uid}) {
    return ds.delete(uid: uid, id: id);
  }

  @override
  Future<void> updateTransferNotes({
    required String id,
    required String notes,
    required String uid,
  }) {
    return ds.updateTransferNotes(uid: uid, id: id, notes: notes);
  }
}
