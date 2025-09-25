import 'package:flutter/services.dart';

class CpfInputFormatter extends TextInputFormatter {
  const CpfInputFormatter();

  static String format(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < d.length && i < 11; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  static String digits(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    return d.length > 11 ? d.substring(0, 11) : d;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = digits(newValue.text);
    final formatted = format(digitsOnly);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}
