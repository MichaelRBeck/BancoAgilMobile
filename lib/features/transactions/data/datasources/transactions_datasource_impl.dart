import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../../../services/transactions_service.dart';
import '../../../../services/transfer_local_service.dart';
import '../../data/models/transaction_model.dart';
import 'transactions_datasource.dart';

class TransactionsDataSourceImpl implements TransactionsDataSource {
  final TransactionsService service;
  final TransferLocalService transferService;
  final fs.FirebaseFirestore db;

  TransactionsDataSourceImpl(
    this.service, {
    required this.transferService,
    required this.db,
  });

  String _digits(String? s) => (s ?? '').replaceAll(RegExp(r'\D'), '');

  bool _cpfMatches({
    required String cpfFilterDigits,
    required TransactionModel t,
  }) {
    if (cpfFilterDigits.isEmpty) return true;

    final docCpf = _digits(t.counterpartyCpf ?? t.destCpf);

    if (cpfFilterDigits.length == 11) return docCpf == cpfFilterDigits;
    return docCpf.startsWith(cpfFilterDigits);
  }

  @override
  Future<TransactionsPageResult> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    required int limit,
    fs.DocumentSnapshot? startAfter,
    String? counterpartyCpf,
  }) async {
    final cpfFilter = _digits(counterpartyCpf);

    final shouldFilterCpf =
        cpfFilter.isNotEmpty &&
        (type == null || type.isEmpty || type == 'transfer');

    final collected = <TransactionModel>[];
    fs.DocumentSnapshot? cursor = startAfter;

    while (collected.length < limit) {
      final remaining = limit - collected.length;

      final (items, last) = await service.fetchPage(
        uid: uid,
        type: (type != null && type.trim().isNotEmpty) ? type.trim() : null,
        start: start,
        end: end,
        limit: remaining,
        startAfter: cursor,
      );

      if (items.isEmpty) {
        return TransactionsPageResult(
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

      cursor = last;

      if (items.length < remaining || last == null) {
        return TransactionsPageResult(
          items: collected,
          nextCursor: cursor,
          hasMore: false,
        );
      }
    }

    return TransactionsPageResult(
      items: collected,
      nextCursor: cursor,
      hasMore: true,
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
    return service.totalsForPeriod(
      uid: uid,
      start: start,
      end: end,
      type: (type != null && type.trim().isNotEmpty) ? type.trim() : null,
      counterpartyCpf: counterpartyCpf,
    );
  }

  double _deltaFor(String type, double amount) {
    if (type == 'income') return amount;
    if (type == 'expense') return -amount;
    return 0.0; // transfer não mexe aqui
  }

  @override
  Future<void> create(TransactionModel model) async {
    // Cria transação (income/expense) + atualiza saldo de forma atômica (sem ir pra UI).
    final userRef = db.collection('users').doc(model.userId);
    final txRef = db.collection('transactions').doc(); // id gerado

    await db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw 'Usuário não encontrado.';

      final data = userSnap.data() as Map<String, dynamic>;
      final curr = (data['balance'] ?? 0);
      final currDouble = (curr is num) ? curr.toDouble() : 0.0;

      final delta = _deltaFor(model.type, model.amount);
      final projected = currDouble + delta;

      if (projected < 0) {
        throw 'Saldo insuficiente para esta operação.';
      }

      tx.update(userRef, {
        'balance': fs.FieldValue.increment(delta),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });

      final map = model.toMap();
      // garante consistência serverTimestamp
      map['createdAt'] = fs.FieldValue.serverTimestamp();
      map['updatedAt'] = fs.FieldValue.serverTimestamp();
      map['date'] = fs.FieldValue.serverTimestamp(); // mantém seu padrão atual

      tx.set(txRef, map);
    });
  }

  @override
  Future<void> update(TransactionModel model) async {
    final txDocRef = db.collection('transactions').doc(model.id);
    final userRef = db.collection('users').doc(model.userId);

    await db.runTransaction((tx) async {
      final oldSnap = await tx.get(txDocRef);
      if (!oldSnap.exists) throw 'Transação não encontrada.';

      final old = TransactionModel.fromDoc(oldSnap);

      // Se for transfer, aqui a regra do seu app é: não edita valor/tipo, só notes via método próprio.
      if (old.type == 'transfer') {
        throw 'Transferências devem ser atualizadas apenas por notes.';
      }

      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw 'Usuário não encontrado.';

      final udata = userSnap.data() as Map<String, dynamic>;
      final curr = (udata['balance'] ?? 0);
      final currDouble = (curr is num) ? curr.toDouble() : 0.0;

      final oldDelta = _deltaFor(old.type, old.amount);
      final newDelta = _deltaFor(model.type, model.amount);

      // “corrige” o saldo: remove efeito antigo + aplica novo
      final projected = currDouble - oldDelta + newDelta;
      if (projected < 0) {
        throw 'Saldo insuficiente após a alteração.';
      }

      final diff = newDelta - oldDelta;

      tx.update(userRef, {
        'balance': fs.FieldValue.increment(diff),
        'updatedAt': fs.FieldValue.serverTimestamp(),
      });

      final map = model.toMap();
      map['updatedAt'] = fs.FieldValue.serverTimestamp();
      tx.update(txDocRef, map);
    });
  }

  @override
  Future<void> updateTransferNotes({
    required String id,
    required String notes,
  }) async {
    await db.collection('transactions').doc(id).update({
      'notes': notes,
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

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
  Future<void> delete(String id) => service.delete(id);
}
