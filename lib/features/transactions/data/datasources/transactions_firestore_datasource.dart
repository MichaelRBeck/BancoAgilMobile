import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionsFirestoreDatasource {
  final CollectionReference _col;

  TransactionsFirestoreDatasource(FirebaseFirestore firestore)
    : _col = firestore.collection('transactions');

  Future<(List<TransactionModel>, DocumentSnapshot?)> fetchPage({
    required String uid,
    String? type,
    DateTime? start,
    DateTime? end,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query q = _col
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true);

    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type);
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
    final items = snap.docs.map(TransactionModel.fromDoc).toList();
    return (items, snap.docs.isEmpty ? null : snap.docs.last);
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
