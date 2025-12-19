import '../../domain/entities/transaction.dart';
import '../../domain/entities/transactions_cursor.dart';
import '../../domain/entities/transactions_page_result.dart';
import '../../domain/repositories/transactions_repository.dart';

import '../cache/transactions_cache_datasource.dart';
import '../datasources/transactions_datasource.dart';
import '../dto/transactions_cursor_dto.dart';
import '../models/transaction_model.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  final TransactionsDataSource ds;
  final TransactionsCacheDataSource cache;

  // Cache em memória (opcional)
  final _pageCache = <String, TransactionsPageResult>{};

  TransactionsRepositoryImpl(this.ds, this.cache);

  String _key({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    String? counterpartyCpf,
    String? cursorId,
    required int limit,
  }) =>
      '$uid|${type ?? ''}|${start?.millisecondsSinceEpoch ?? 0}|${end?.millisecondsSinceEpoch ?? 0}|${counterpartyCpf ?? ''}|${cursorId ?? ''}|$limit';

  String _signature({
    String? type,
    DateTime? start,
    DateTime? end,
    String? counterpartyCpf,
    required int limit,
  }) =>
      '${type ?? ''}|${start?.millisecondsSinceEpoch ?? 0}|${end?.millisecondsSinceEpoch ?? 0}|${counterpartyCpf ?? ''}|$limit';

  bool _isFirstPage(TransactionsCursor? startAfter) => startAfter == null;

  Future<void> _invalidateAllForUser(String uid) async {
    // 1) limpa memória
    _pageCache.removeWhere((k, _) => k.startsWith('$uid|'));

    // 2) limpa Hive (aguarda pra evitar corrida)
    await cache.clearUser(uid);
  }

  Future<void> _invalidateForEntity(Transaction entity) async {
    // Sempre invalida o dono do registro (userId)
    await _invalidateAllForUser(entity.userId);

    // Se for transfer, também invalida origin/dest (se existir)
    if (entity.type == 'transfer') {
      final originUid = (entity.originUid ?? '').trim();
      final destUid = (entity.destUid ?? '').trim();

      if (originUid.isNotEmpty && originUid != entity.userId) {
        await _invalidateAllForUser(originUid);
      }
      if (destUid.isNotEmpty && destUid != entity.userId) {
        await _invalidateAllForUser(destUid);
      }
    }
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
    final cursorId = startAfter?.docId;

    final key = _key(
      uid: uid,
      type: type,
      start: start,
      end: end,
      counterpartyCpf: counterpartyCpf,
      cursorId: cursorId,
      limit: limit,
    );

    // 0) cache em memória
    final memCached = _pageCache[key];
    if (memCached != null) return memCached;

    final isFirst = _isFirstPage(startAfter);
    final sig = _signature(
      type: type,
      start: start,
      end: end,
      counterpartyCpf: counterpartyCpf,
      limit: limit,
    );

    // 1) cache em disco SOMENTE para primeira página
    if (isFirst) {
      final cachedModels = await cache.readFirstPage(uid: uid, signature: sig);
      if (cachedModels.isNotEmpty) {
        final result = TransactionsPageResult(
          items: cachedModels.map((m) => m.toEntity()).toList(growable: false),
          nextCursor:
              null, // cursor real virá no fetch real / próxima paginação
          hasMore: true,
        );
        _pageCache[key] = result;
        return result;
      }
    }

    // 2) fetch real
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

    final result = TransactionsPageResult(
      items: page.items.map((m) => m.toEntity()).toList(growable: false),
      nextCursor: page.nextCursor?.toEntity(),
      hasMore: page.hasMore,
    );

    // 2.1) salva em memória
    _pageCache[key] = result;

    // 3) escreve cache em disco apenas 1ª página
    if (isFirst) {
      await cache.writeFirstPage(uid: uid, signature: sig, items: page.items);
    }

    return result;
  }

  @override
  Future<void> create(Transaction entity) async {
    await ds.create(
      uid: entity.userId,
      model: TransactionModel.fromEntity(entity),
    );
    await _invalidateForEntity(entity);
  }

  @override
  Future<void> update(Transaction entity) async {
    await ds.update(
      uid: entity.userId,
      model: TransactionModel.fromEntity(entity),
    );
    await _invalidateForEntity(entity);
  }

  @override
  Future<void> delete(String id, {required String uid}) async {
    await ds.delete(uid: uid, id: id);

    // delete não tem entity pra saber origin/dest; invalida ao menos o uid
    await _invalidateAllForUser(uid);
  }

  @override
  Future<void> invalidateUserCache(String uid) async {
    _invalidateAllForUser(uid);
  }

  @override
  Future<void> updateTransferNotes({
    required String id,
    required String notes,
    required String uid,
  }) async {
    await ds.updateTransferNotes(uid: uid, id: id, notes: notes);

    // notas alteram listagem => invalida
    await _invalidateAllForUser(uid);
  }
}
