import '../../../../services/transactions_service.dart';
import '../dto/transactions_cursor_dto.dart';
import '../models/transaction_model.dart';
import 'transactions_datasource.dart';

class TransactionsDataSourceImpl implements TransactionsDataSource {
  final TransactionsService service;
  TransactionsDataSourceImpl(this.service);

  String _digits(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');

  bool _cpfMatches({
    required String cpfFilterDigits,
    required TransactionModel t,
  }) {
    if (cpfFilterDigits.isEmpty) return true;

    // seu dado pode estar em counterpartyCpf ou destCpf (transfer)
    final docCpf = _digits(t.counterpartyCpf ?? t.destCpf);

    if (cpfFilterDigits.length == 11) return docCpf == cpfFilterDigits;
    return docCpf.startsWith(cpfFilterDigits);
  }

  @override
  Future<TransactionsPageDto> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    TransactionsCursorDto? startAfter,
    String? counterpartyCpf,
  }) async {
    final cpfFilter = _digits(counterpartyCpf);

    final shouldFilterCpf =
        cpfFilter.isNotEmpty &&
        (type == null || type.isEmpty || type == 'transfer');

    final collected = <TransactionModel>[];
    TransactionsCursorDto? cursor = startAfter;

    while (collected.length < limit) {
      final remaining = limit - collected.length;

      final (items, lastCursor) = await service.fetchPage(
        uid: uid,
        type: (type != null && type.trim().isNotEmpty) ? type.trim() : null,
        start: start,
        end: end,
        limit: remaining,
        startAfter: cursor,
      );

      if (items.isEmpty) {
        return TransactionsPageDto(
          items: collected,
          nextCursor: cursor,
          hasMore: false,
        );
      }

      final filtered = shouldFilterCpf
          ? items
                .where(
                  (t) =>
                      t.type == 'transfer' &&
                      _cpfMatches(cpfFilterDigits: cpfFilter, t: t),
                )
                .toList()
          : items;

      collected.addAll(filtered);
      cursor = lastCursor;

      // se veio menos do que pediu, ou não tem lastCursor, acabou
      if (items.length < remaining || lastCursor == null) {
        return TransactionsPageDto(
          items: collected,
          nextCursor: cursor,
          hasMore: false,
        );
      }
    }

    return TransactionsPageDto(
      items: collected,
      nextCursor: cursor,
      hasMore: true,
    );
  }

  @override
  Future<void> create(TransactionModel model) => service.add(model);

  @override
  Future<void> update(TransactionModel model) => service.update(model);

  @override
  Future<void> delete(String id) => service.delete(id);

  @override
  Future<void> updateTransferNotes({
    required String id,
    required String notes,
  }) {
    // mantém no service (infra) pra este datasource não falar com Firestore direto
    return service.updateTransferNotes(id: id, notes: notes);
  }
}
