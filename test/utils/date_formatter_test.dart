import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/utils/date_formatter.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 29, 9, 0);

  test('formatDate pads day and month', () {
    expect(formatDate(DateTime(2026, 3, 5)), '05/03/2026');
  });

  test('formatDateTime shows time before date', () {
    expect(formatDateTime(DateTime(2026, 3, 5, 7, 4)), '07:04 05/03/2026');
  });

  test('formatDueDate uses friendly words near today', () {
    expect(formatDueDate(DateTime(2026, 10, 28), now: now), 'Hôm qua');
    expect(formatDueDate(DateTime(2026, 10, 29), now: now), 'Hôm nay');
    expect(formatDueDate(DateTime(2026, 10, 30), now: now), 'Ngày mai');
    expect(formatDueDate(DateTime(2026, 11, 15), now: now), '15/11/2026');
  });
}
