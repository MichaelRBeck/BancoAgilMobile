import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    super.name,
    super.cpf,
    super.balance,
  });

  factory AppUserModel.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserModel(
      uid: uid,
      name: map['name'] as String?,
      cpf: map['cpf'] as String?,
      balance: (map['balance'] as num?),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'cpf': cpf,
    'balance': balance,
  };
}
