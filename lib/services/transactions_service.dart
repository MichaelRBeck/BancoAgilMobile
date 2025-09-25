import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionsService {
  final _col = FirebaseFirestore.instance.collection('transactions');

  Stream<List<TransactionModel>> streamForUser(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => TransactionModel.fromDoc(d)).toList(),
        );
  }

  Future<(List<TransactionModel>, DocumentSnapshot?)> fetchPage({
    required String uid,
    String? type, // 'income' | 'expense' | 'transfer'
    DateTime? start,
    DateTime? end,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query q = _col
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true);

    if (type != null && type.trim().isNotEmpty) {
      q = q.where('type', isEqualTo: type.trim());
    }
    if (start != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get();
    final docs = snap.docs;
    final items = docs.map((d) => TransactionModel.fromDoc(d)).toList();
    final last = docs.isEmpty ? null : docs.last;
    return (items, last);
  }

  Future<void> add(TransactionModel t) async {
    await _col.add(t.toMap());
  }

  Future<void> update(TransactionModel t) async {
    await _col.doc(t.id).update(t.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// Totais do período com opção de filtrar por tipo e por CPF do destinatário (transferências).
  /// Filtro por CPF é aplicado em código para evitar novos índices.
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
    String? type, // se informado, considera apenas esse tipo
    String?
    counterpartyCpf, // se informado e type == 'transfer', filtra transfers por CPF (igual/prefixo)
    int chunk = 500,
  }) async {
    double income = 0, expense = 0, transferIn = 0, transferOut = 0;

    Query q = _col
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true);
    if (start != null) {
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    String digits(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');
    final cpfFilter = digits(counterpartyCpf);

    DocumentSnapshot? cursor;
    while (true) {
      final snap =
          await (cursor == null
                  ? q.limit(chunk)
                  : q.startAfterDocument(cursor).limit(chunk))
              .get();
      if (snap.docs.isEmpty) break;

      for (final d in snap.docs) {
        final t = TransactionModel.fromDoc(d);

        // filtro de tipo
        if (type != null && type.isNotEmpty && t.type != type) continue;

        // filtro de CPF (apenas transferências)
        if (cpfFilter.isNotEmpty && t.type == 'transfer') {
          final docCpf = digits(t.counterpartyCpf ?? t.destCpf);
          final matches = cpfFilter.length == 11
              ? docCpf == cpfFilter
              : docCpf.startsWith(cpfFilter);
          if (!matches) continue;
        }

        switch (t.type) {
          case 'income':
            income += t.amount;
            break;
          case 'expense':
            expense += t.amount;
            break;
          case 'transfer':
            // saída se o dono do doc for o originUid; entrada se for o destUid
            final isOut = (t.originUid != null && t.originUid == t.userId);
            if (isOut) {
              transferOut += t.amount;
            } else {
              transferIn += t.amount;
            }
            break;
        }
      }

      cursor = snap.docs.last;
      if (snap.docs.length < chunk) break;
    }

    final transferNet = transferIn - transferOut;
    return (
      income: income,
      expense: expense,
      transferIn: transferIn,
      transferOut: transferOut,
      transferNet: transferNet,
    );
  }
}
