import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../../domain/entities/transactions_cursor.dart';

class TransactionsCursorDto {
  final fs.Timestamp date;
  final String docId;

  const TransactionsCursorDto({required this.date, required this.docId});

  factory TransactionsCursorDto.fromEntity(TransactionsCursor e) {
    return TransactionsCursorDto(
      date: fs.Timestamp.fromDate(e.date),
      docId: e.docId,
    );
  }

  TransactionsCursor toEntity() {
    return TransactionsCursor(date: date.toDate(), docId: docId);
  }
}
