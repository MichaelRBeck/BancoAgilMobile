import 'package:cloud_firestore/cloud_firestore.dart';

import '../dto/transactions_cursor_dto.dart';
import '../models/transaction_model.dart';
import 'transactions_datasource.dart';

class TransactionsFirestoreDataSource implements TransactionsDataSource {
  final FirebaseFirestore firestore;
  final CollectionReference<Map<String, dynamic>> _col;

  TransactionsFirestoreDataSource(this.firestore)
    : _col = firestore.collection('transactions');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      firestore.collection('users').doc(uid);

  bool _isNewId(String id) => id.isEmpty || id == 'new';
  String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  double _impactFor(String type, double amount) {
    final v = amount.abs();
    switch (type) {
      case 'income':
        return v;
      case 'expense':
        return -v;
      default:
        return 0;
    }
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
    Query<Map<String, dynamic>> base = _col
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .orderBy(FieldPath.documentId, descending: true);

    if (type != null && type.isNotEmpty) {
      base = base.where('type', isEqualTo: type);
    }
    if (start != null) {
      base = base.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (end != null) {
      base = base.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    final cpfDigits =
        (counterpartyCpf != null && counterpartyCpf.trim().isNotEmpty)
        ? _digits(counterpartyCpf)
        : null;

    if (cpfDigits == null || cpfDigits.isEmpty) {
      Query<Map<String, dynamic>> q = base;
      if (startAfter != null) {
        q = q.startAfter([startAfter.date, startAfter.docId]);
      }

      final snap = await q.limit(limit).get();
      final items = snap.docs.map(TransactionModel.fromDoc).toList();

      final lastDoc = snap.docs.isEmpty ? null : snap.docs.last;
      final nextCursor = lastDoc == null
          ? null
          : TransactionsCursorDto(
              date: (lastDoc.get('date') as Timestamp),
              docId: lastDoc.id,
            );

      return TransactionsPageDto(
        items: items,
        nextCursor: nextCursor,
        hasMore: snap.docs.length == limit,
      );
    }

    final results = <TransactionModel>[];

    // controle de cursor do "scan"
    Timestamp? scanDate = startAfter?.date;
    String? scanDocId = startAfter?.docId;

    // batch maior para reduzir roundtrips
    const int batchSize = 60;

    bool hasMore = true;
    TransactionsCursorDto? nextCursor;

    while (results.length < limit && hasMore) {
      Query<Map<String, dynamic>> q = base;

      if (scanDate != null && scanDocId != null) {
        q = q.startAfter([scanDate, scanDocId]);
      }

      final snap = await q.limit(batchSize).get();
      if (snap.docs.isEmpty) {
        hasMore = false;
        break;
      }

      for (final d in snap.docs) {
        final data = d.data();
        final c1 = _digits((data['counterpartyCpf'] ?? '').toString());
        final c2 = _digits((data['originCpf'] ?? '').toString());
        final c3 = _digits((data['destCpf'] ?? '').toString());

        if (c1 == cpfDigits || c2 == cpfDigits || c3 == cpfDigits) {
          results.add(TransactionModel.fromDoc(d));
          if (results.length >= limit) break;
        }
      }

      final last = snap.docs.last;
      scanDate = (last.get('date') as Timestamp);
      scanDocId = last.id;

      nextCursor = TransactionsCursorDto(date: scanDate!, docId: scanDocId!);

      hasMore = snap.docs.length == batchSize;
    }

    return TransactionsPageDto(
      items: results,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  @override
  Future<void> create({
    required String uid,
    required TransactionModel model,
  }) async {
    final isNew = _isNewId(model.id);

    // Transfer não mexe no balance aqui
    if (model.type == 'transfer') {
      if (isNew) {
        await _col.add(model.toMap());
      } else {
        await _col.doc(model.id).set(model.toMap(), SetOptions(merge: true));
      }
      return;
    }

    final impact = _impactFor(model.type, model.amount);

    await firestore.runTransaction((tx) async {
      final docRef = isNew ? _col.doc() : _col.doc(model.id);

      tx.set(docRef, model.toMap(), SetOptions(merge: true));

      tx.set(_userDoc(uid), {
        'balance': FieldValue.increment(impact),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> update({
    required String uid,
    required TransactionModel model,
  }) async {
    if (model.type == 'transfer') {
      await _col.doc(model.id).set(model.toMap(), SetOptions(merge: true));
      return;
    }

    final ref = _col.doc(model.id);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Transação não encontrada.');

      final data = snap.data() as Map<String, dynamic>;
      final oldType = (data['type'] ?? '') as String;
      final oldAmount =
          (data['amount'] as num?)?.toDouble() ??
          (data['value'] as num?)?.toDouble() ??
          0.0;

      final oldImpact = _impactFor(oldType, oldAmount);
      final newImpact = _impactFor(model.type, model.amount);
      final delta = newImpact - oldImpact;

      tx.set(ref, model.toMap(), SetOptions(merge: true));

      if (delta != 0) {
        tx.set(_userDoc(uid), {
          'balance': FieldValue.increment(delta),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<void> delete({required String uid, required String id}) async {
    final ref = _col.doc(id);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final type = (data['type'] ?? '') as String;

      // Transfer não mexe no balance aqui
      if (type == 'transfer') {
        tx.delete(ref);
        return;
      }

      final amount =
          (data['amount'] as num?)?.toDouble() ??
          (data['value'] as num?)?.toDouble() ??
          0.0;

      final impact = _impactFor(type, amount);

      tx.set(_userDoc(uid), {
        'balance': FieldValue.increment(-impact),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.delete(ref);
    });
  }

  @override
  Future<void> updateTransferNotes({
    required String uid,
    required String id,
    required String notes,
  }) {
    return _col.doc(id).set({
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
