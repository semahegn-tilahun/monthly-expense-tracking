import 'package:intl/intl.dart';

String money(num value) {
  final formatted = NumberFormat('#,##0.00').format(value);
  return 'ETB $formatted';
}

String compactMoney(num value) {
  final formatted = NumberFormat.compact().format(value);
  return 'ETB $formatted';
}

double parseMoney(String input) {
  final cleaned = input.replaceAll(',', '').trim();
  return double.tryParse(cleaned) ?? 0;
}
