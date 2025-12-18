import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  final String uid;
  final String fullName;
  final String cpfDigits;
  final double balance;

  const UserProfileModel({
    required this.uid,
    required this.fullName,
    required this.cpfDigits,
    required this.balance,
  });

  UserProfile toEntity() => UserProfile(
    uid: uid,
    fullName: fullName,
    cpfDigits: cpfDigits,
    balance: balance,
  );

  static UserProfileModel fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return UserProfileModel(
      uid: uid,
      fullName: (data['fullName'] ?? '').toString(),
      cpfDigits: (data['cpf'] ?? '').toString(),
      balance: ((data['balance'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'cpf': cpfDigits,
    'balance': balance,
  };
}
