/*
class TransactionModel {
  final String id;

  // usado por income/expense e também por transfer (espelho do dono)
  final String userId;

  /// 'income' | 'expense' | 'transfer'
  final String type;

  final String category;
  final double amount;
  final DateTime date;
  final String? notes;

  final String? receiptBase64;
  final String? contentType;

  final String? originUid;
  final String? destUid;
  final String? originCpf;
  final String? destCpf;
  final String? status; // e.g., 'completed'

  final String? counterpartyUid;
  final String? counterpartyCpf; // somente dígitos
  final String? counterpartyName; // nome completo

  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.receiptBase64,
    this.contentType,
    this.originUid,
    this.destUid,
    this.originCpf,
    this.destCpf,
    this.status,
    this.counterpartyUid,
    this.counterpartyCpf,
    this.counterpartyName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type,
    'category': category,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'notes': notes,
    'receiptBase64': receiptBase64,
    'contentType': contentType,
    'originUid': originUid,
    'destUid': destUid,
    'originCpf': originCpf,
    'destCpf': destCpf,
    'status': status,
    'counterpartyUid': counterpartyUid,
    'counterpartyCpf': counterpartyCpf,
    'counterpartyName': counterpartyName,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime _ts(dynamic x) => (x as Timestamp).toDate();

    return TransactionModel(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      type: data['type'] as String,
      category: (data['category'] ?? '') as String,
      amount: (data['amount'] as num).toDouble(),
      date: _ts(data['date']),
      notes: data['notes'] as String?,
      receiptBase64: data['receiptBase64'] as String?,
      contentType: data['contentType'] as String?,
      originUid: data['originUid'] as String?,
      destUid: data['destUid'] as String?,
      originCpf: data['originCpf'] as String?,
      destCpf: data['destCpf'] as String?,
      status: data['status'] as String?,
      counterpartyUid: data['counterpartyUid'] as String?,
      counterpartyCpf: data['counterpartyCpf'] as String?,
      counterpartyName: data['counterpartyName'] as String?,
      createdAt: _ts(data['createdAt']),
      updatedAt: _ts(data['updatedAt']),
    );
  }
}

*/

class Transaction {
  final String id;
  final String userId;
  final String type;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;

  final String? receiptBase64;
  final String? contentType;

  final String? originUid;
  final String? destUid;
  final String? originCpf;
  final String? destCpf;
  final String? status;

  final String? counterpartyUid;
  final String? counterpartyCpf;
  final String? counterpartyName;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.receiptBase64,
    this.contentType,
    this.originUid,
    this.destUid,
    this.originCpf,
    this.destCpf,
    this.status,
    this.counterpartyUid,
    this.counterpartyCpf,
    this.counterpartyName,
    required this.createdAt,
    required this.updatedAt,
  });
}
