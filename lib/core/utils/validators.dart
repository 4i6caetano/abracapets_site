import 'formatters.dart';

typedef Validator = String? Function(String? value);


abstract final class Validators {
  static Validator required([String message = 'Campo obrigatório']) =>
      (value) => (value == null || value.trim().isEmpty) ? message : null;

  static Validator minLength(int min, {String? label}) => (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return '${label ?? 'Campo'} obrigatório';
        if (v.length < min) return 'Mínimo de $min caracteres';
        return null;
      };

  static Validator maxLength(int max) => (value) =>
      (value != null && value.length > max) ? 'Máximo de $max caracteres' : null;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe o e-mail';
    final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v);
    return ok ? null : 'E-mail inválido';
  }

  
  static List<(String, bool)> passwordRules(String value) => [
        ('Ao menos 8 caracteres', value.length >= 8),
        ('Uma letra maiúscula', RegExp(r'[A-Z]').hasMatch(value)),
        ('Uma letra minúscula', RegExp(r'[a-z]').hasMatch(value)),
        ('Um número', RegExp(r'\d').hasMatch(value)),
      ];

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Informe a senha';
    for (final (label, ok) in passwordRules(v)) {
      if (!ok) return 'A senha precisa de: ${label.toLowerCase()}';
    }
    return null;
  }

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe o telefone';
    if (digits.length < 10 || digits.length > 11) return 'Telefone inválido';
    return null;
  }

  static String? money(String? value) {
    final parsed = Fmt.parseCurrency(value ?? '');
    if (parsed == null) return 'Informe o valor';
    if (parsed <= 0) return 'O valor deve ser maior que zero';
    if (parsed > 1000000) return 'Valor muito alto';
    return null;
  }

  static String? cpf(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Informe o CPF';
    if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
      return 'CPF inválido';
    }
    int calc(int len) {
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += int.parse(digits[i]) * (len + 1 - i);
      }
      final mod = (sum * 10) % 11;
      return mod == 10 ? 0 : mod;
    }

    if (calc(9) != int.parse(digits[9]) || calc(10) != int.parse(digits[10])) {
      return 'CPF inválido';
    }
    return null;
  }

  static Validator compose(List<Validator> validators) => (value) {
        for (final v in validators) {
          final result = v(value);
          if (result != null) return result;
        }
        return null;
      };
}
