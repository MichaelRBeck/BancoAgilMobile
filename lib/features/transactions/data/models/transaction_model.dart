import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.category,
    required super.amount,
    required super.date,
    super.notes,
    super.receiptBase64,
    super.contentType,
    super.originUid,
    super.destUid,
    super.originCpf,
    super.destCpf,
    super.status,
    super.counterpartyUid,
    super.counterpartyCpf,
    super.counterpartyName,
    required super.createdAt,
    required super.updatedAt,
  });

  Transaction toEntity() => Transaction(
    id: id,
    userId: userId,
    type: type,
    category: category,
    amount: amount,
    date: date,
    notes: notes,
    receiptBase64: receiptBase64,
    contentType: contentType,
    originUid: originUid,
    destUid: destUid,
    originCpf: originCpf,
    destCpf: destCpf,
    status: status,
    counterpartyUid: counterpartyUid,
    counterpartyCpf: counterpartyCpf,
    counterpartyName: counterpartyName,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory TransactionModel.fromEntity(Transaction t) => TransactionModel(
    id: t.id,
    userId: t.userId,
    type: t.type,
    category: t.category,
    amount: t.amount,
    date: t.date,
    notes: t.notes,
    receiptBase64: t.receiptBase64,
    contentType: t.contentType,
    originUid: t.originUid,
    destUid: t.destUid,
    originCpf: t.originCpf,
    destCpf: t.destCpf,
    status: t.status,
    counterpartyUid: t.counterpartyUid,
    counterpartyCpf: t.counterpartyCpf,
    counterpartyName: t.counterpartyName,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  );

  String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type,
    'category': category,
    'amount': amount,
    'date': fs.Timestamp.fromDate(date),
    'notes': notes,
    'receiptBase64': receiptBase64,
    'contentType': contentType,
    'originUid': originUid,
    'destUid': destUid,
    'originCpf': originCpf == null ? null : _digits(originCpf!),
    'destCpf': destCpf == null ? null : _digits(destCpf!),
    'counterpartyCpf': counterpartyCpf == null
        ? null
        : _digits(counterpartyCpf!),
    'status': status,
    'counterpartyUid': counterpartyUid,

    'counterpartyName': counterpartyName,
    'createdAt': fs.Timestamp.fromDate(createdAt),
    'updatedAt': fs.Timestamp.fromDate(updatedAt),
  };

  factory TransactionModel.fromDoc(fs.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime ts(x) => (x as fs.Timestamp).toDate();

    final cpfLower = data['counterpartyCpf'] as String?;
    final cpfUpper = data['counterPartyCpf'] as String?;
    final resolvedCpf = (cpfLower != null && cpfLower.isNotEmpty)
        ? cpfLower
        : (cpfUpper ?? '');

    return TransactionModel(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      amount: (data['amount'] as num).toDouble(),
      date: ts(data['date']),
      notes: data['notes'] as String?,
      receiptBase64: data['receiptBase64'] as String?,
      contentType: data['contentType'] as String?,
      originUid: data['originUid'] as String?,
      destUid: data['destUid'] as String?,
      originCpf: data['originCpf'] as String?,
      destCpf: data['destCpf'] as String?,
      status: data['status'] as String?,
      counterpartyUid: data['counterpartyUid'] as String?,
      counterpartyCpf: resolvedCpf.isEmpty ? null : resolvedCpf,
      counterpartyName: data['counterpartyName'] as String?,
      createdAt: ts(data['createdAt']),
      updatedAt: ts(data['updatedAt']),
    );
  }
}
