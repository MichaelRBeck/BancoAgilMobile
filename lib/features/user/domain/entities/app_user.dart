class AppUser {
  final String uid;
  final String? name;
  final String? cpf;
  final num? balance;

  const AppUser({required this.uid, this.name, this.cpf, this.balance});

  AppUser copyWith({String? name, String? cpf, num? balance}) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      cpf: cpf ?? this.cpf,
      balance: balance ?? this.balance,
    );
  }
}
