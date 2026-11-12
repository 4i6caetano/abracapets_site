import 'package:intl/intl.dart';

abstract final class Fmt {
  static final _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  static final _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _monthYear = DateFormat("MMMM 'de' yyyy", 'pt_BR');
  static final _monthShort = DateFormat('MMM', 'pt_BR');
  static final _dayMonth = DateFormat("dd 'de' MMM", 'pt_BR');

  static String currency(double value) => _currency.format(value);

  static String signedCurrency(double value, {required bool income}) =>
      '${income ? '+' : '−'} ${_currency.format(value.abs())}';

  static String date(DateTime date) => _date.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);
  static String monthShort(DateTime date) => _capitalize(_monthShort.format(date));

  static String monthYear(DateTime date) =>
      _capitalize(_monthYear.format(date));

  static String monthName(int month) =>
      _capitalize(DateFormat('MMMM', 'pt_BR').format(DateTime(2000, month)));

  
  static String relative(DateTime date, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final diff = DateTime(ref.year, ref.month, ref.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff < 0) return 'em ${Fmt.date(date)}';
    if (diff == 0) return 'hoje';
    if (diff == 1) return 'ontem';
    if (diff < 7) return 'há $diff dias';
    if (diff < 30) {
      final w = diff ~/ 7;
      return 'há $w ${w == 1 ? 'semana' : 'semanas'}';
    }
    final m = diff ~/ 30;
    if (m < 12) return 'há $m ${m == 1 ? 'mês' : 'meses'}';
    final y = m ~/ 12;
    return 'há $y ${y == 1 ? 'ano' : 'anos'}';
  }

  
  static String age(DateTime birth, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    var months = (ref.year - birth.year) * 12 + ref.month - birth.month;
    if (ref.day < birth.day) months--;
    if (months < 1) return 'menos de 1 mês';
    if (months < 12) return '$months ${months == 1 ? 'mês' : 'meses'}';
    final years = months ~/ 12;
    return '$years ${years == 1 ? 'ano' : 'anos'}';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  
  static double? parseCurrency(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.contains(',')
        ? cleaned.replaceAll('.', '').replaceAll(',', '.')
        : cleaned;
    return double.tryParse(normalized);
  }

  static String maskCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return cpf;
    return '***.${digits.substring(3, 6)}.***-**';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
