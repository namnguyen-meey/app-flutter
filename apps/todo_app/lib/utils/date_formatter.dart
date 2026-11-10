/// Small helpers to display dates in the Vietnamese format (dd/MM/yyyy).
library;

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formats a date as `29/10/2026`.
String formatDate(DateTime date) {
  return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
}

/// Formats a date and time as `14:05 29/10/2026`.
String formatDateTime(DateTime dateTime) {
  final String time =
      '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  return '$time ${formatDate(dateTime)}';
}

/// Formats a deadline, using friendly words for yesterday, today and
/// tomorrow.
String formatDueDate(DateTime dueDate, {DateTime? now}) {
  final DateTime current = now ?? DateTime.now();
  // UTC dates avoid off-by-one errors on days with daylight saving changes.
  final DateTime today = DateTime.utc(current.year, current.month, current.day);
  final DateTime due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
  final int daysFromToday = due.difference(today).inDays;

  return switch (daysFromToday) {
    -1 => 'Hôm qua',
    0 => 'Hôm nay',
    1 => 'Ngày mai',
    _ => formatDate(dueDate),
  };
}
