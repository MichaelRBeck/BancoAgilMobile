class UserProfile {
  final String uid;
  final String fullName;
  final String cpfDigits;
  final double balance;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.cpfDigits,
    required this.balance,
  });

  UserProfile copyWith({String? fullName, String? cpfDigits, double? balance}) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      cpfDigits: cpfDigits ?? this.cpfDigits,
      balance: balance ?? this.balance,
    );
  }
}
