import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String cpf; // 11 dígitos (sem máscara)
  final String email;
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.cpf,
    required this.email,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'cpf': cpf,
    'email': email,
    'balance': balance,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
  };

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return UserProfile(
      uid: doc.id,
      fullName: (data['fullName'] ?? '').toString(),
      cpf: (data['cpf'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      balance: (data['balance'] ?? 0).toDouble(),
      createdAt: _ts(data['createdAt']),
      updatedAt: _ts(data['updatedAt']),
    );
  }
}
