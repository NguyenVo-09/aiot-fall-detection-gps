import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(int timestampSecs) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampSecs * 1000);
    return DateFormat('HH:mm:ss').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('HH:mm:ss, dd/MM').format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
