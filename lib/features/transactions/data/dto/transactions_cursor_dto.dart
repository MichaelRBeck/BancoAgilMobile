import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class TransactionsCursorDto {
  final fs.Timestamp date;
  final String docId;

  const TransactionsCursorDto({required this.date, required this.docId});
}
