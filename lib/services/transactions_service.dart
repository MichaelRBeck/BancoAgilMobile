import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../features/transactions/data/datasources/transactions_firestore_datasource.dart';
import '../features/transactions/data/dto/transactions_cursor_dto.dart';
import '../features/transactions/data/models/transaction_model.dart';

class TransactionsService {
  final fs.CollectionReference _col;
  final TransactionsFirestoreDatasource firestoreDs;

  TransactionsService(fs.FirebaseFirestore firestore)
    : _col = firestore.collection('transactions'),
      firestoreDs = TransactionsFirestoreDatasource(firestore);

  fs.DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      fs.FirebaseFirestore.instance.collection('users').doc(uid);

  double _impactFor(String type, double amount) {
    final v = amount.abs();
    switch (type) {
      case 'income':
        return v;
      case 'expense':
        return -v;
      default:
        return 0; // transfer ou desconhecido
    }
  }

  Stream<List<TransactionModel>> streamForUser(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .orderBy(fs.FieldPath.documentId, descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TransactionModel.fromDoc).toList());
  }

  Future<(List<TransactionModel>, TransactionsCursorDto?)> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    int limit = 20,
    TransactionsCursorDto? startAfter,
  }) {
    return firestoreDs.fetchPage(
      uid: uid,
      type: type,
      start: start,
      end: end,
      limit: limit,
      startAfter: startAfter,
    );
  }

  // ✅ CREATE: atualiza users.balance no mesmo commit (income/expense)
  Future<void> add(TransactionModel t) async {
    if (t.type == 'transfer') {
      await _col.add(t.toMap());
      return;
    }

    final impact = _impactFor(t.type, t.amount);

    await fs.FirebaseFirestore.instance.runTransaction((tx) async {
      final newDoc = _col.doc(); // gera ID
      tx.set(newDoc, t.toMap());

      tx.set(_userDoc(t.userId), {
        'balance': fs.FieldValue.increment(impact),
      }, fs.SetOptions(merge: true));
    });
  }

  // ✅ UPDATE: aplica delta no saldo (income/expense)
  Future<void> update(TransactionModel t) async {
    if (t.type == 'transfer') {
      await _col.doc(t.id).update(t.toMap());
      return;
    }

    final ref = _col.doc(t.id);

    await fs.FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transação não encontrada.');

      final data = (snap.data() as Map<String, dynamic>);

      final oldType = (data['type'] ?? '') as String;
      final oldAmount =
          (data['amount'] as num?)?.toDouble() ??
          (data['value'] as num?)?.toDouble() ??
          0.0;

      final userId = (data['userId'] ?? t.userId) as String;

      final oldImpact = _impactFor(oldType, oldAmount);
      final newImpact = _impactFor(t.type, t.amount);
      final delta = newImpact - oldImpact;

      tx.update(ref, t.toMap());

      if (delta != 0) {
        tx.set(_userDoc(userId), {
          'balance': fs.FieldValue.increment(delta),
        }, fs.SetOptions(merge: true));
      }
    });
  }

  // ✅ DELETE: desfaz impacto no saldo (income/expense)
  Future<void> delete(String id) async {
    final ref = _col.doc(id);

    await fs.FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = (snap.data() as Map<String, dynamic>);
      final type = (data['type'] ?? '') as String;

      // transfer: não mexe aqui (TransferLocalService é o dono dessa regra)
      if (type == 'transfer') {
        tx.delete(ref);
        return;
      }

      final userId = (data['userId'] ?? '') as String;
      final amount =
          (data['amount'] as num?)?.toDouble() ??
          (data['value'] as num?)?.toDouble() ??
          0.0;

      final impact = _impactFor(type, amount);

      tx.set(_userDoc(userId), {
        'balance': fs.FieldValue.increment(-impact),
      }, fs.SetOptions(merge: true));

      tx.delete(ref);
    });
  }

  Future<void> updateTransferNotes({
    required String id,
    required String notes,
  }) async {
    await _col.doc(id).update({
      'notes': notes,
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

  // (seu totalsForPeriod continua igual — já está OK)
}
