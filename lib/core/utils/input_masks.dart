import 'package:flutter/services.dart';


class MaskInputFormatter extends TextInputFormatter {
  MaskInputFormatter(this.pattern);

  final String pattern;

  factory MaskInputFormatter.cpf() => MaskInputFormatter('###.###.###-##');
  factory MaskInputFormatter.phone() => MaskInputFormatter('(##) #####-####');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    var di = 0;
    for (var i = 0; i < pattern.length && di < digits.length; i++) {
      if (pattern[i] == '#') {
        buffer.write(digits[di++]);
      } else {
        buffer.write(pattern[i]);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}


final moneyInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'));
