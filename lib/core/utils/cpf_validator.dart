class CpfValidator {
  static String onlyDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  static String normalize(String input) => onlyDigits(input);

  static bool isValid(String cpf) {
    final d = onlyDigits(cpf);
    return d.length == 11;
  }
}
