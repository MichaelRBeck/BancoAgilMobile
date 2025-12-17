class TransactionsFilter {
  final String type; // '', 'income', 'expense', 'transfer'
  final DateTime? start;
  final DateTime? end;
  final String counterpartyCpfDigits; // só dígitos

  const TransactionsFilter({
    this.type = '',
    this.start,
    this.end,
    this.counterpartyCpfDigits = '',
  });

  TransactionsFilter copyWith({
    String? type,
    DateTime? start,
    DateTime? end,
    String? counterpartyCpfDigits,
  }) {
    return TransactionsFilter(
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      counterpartyCpfDigits:
          counterpartyCpfDigits ?? this.counterpartyCpfDigits,
    );
  }

  bool get isEmpty =>
      type.isEmpty &&
      start == null &&
      end == null &&
      counterpartyCpfDigits.isEmpty;
}
