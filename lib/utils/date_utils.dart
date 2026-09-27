import 'package:intl/intl.dart';

String monthKey([DateTime? date]) {
  return DateFormat('yyyy-MM').format(date ?? DateTime.now());
}

String readableDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

DateTime parseDate(String value) {
  return DateTime.tryParse(value) ?? DateTime.now();
}
