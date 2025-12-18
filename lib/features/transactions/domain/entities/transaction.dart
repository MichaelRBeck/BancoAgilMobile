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
