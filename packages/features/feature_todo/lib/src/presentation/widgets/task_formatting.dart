// =============================================================================
// task_formatting.dart: chuyển dữ liệu công việc thành chữ hiển thị.
//
// Thuộc: feature_todo/presentation.
//
// Domain chỉ biết `TaskPriority.high`, `TaskFilter.active`... Đổi thành chữ
// theo ngôn ngữ đang chọn là việc của tầng presentation, qua l10n.
//
// Ngày tháng dùng MỘT định dạng số `dd/MM/yyyy` cho mọi ngôn ngữ (giống Todo
// app cũ), chỉ "hôm qua/hôm nay/ngày mai" là được dịch. Định dạng theo vùng
// (`DateFormat.yMd(locale)`) cần nạp dữ liệu ngày tháng của từng ngôn ngữ
// trước, mà widget test thường không nạp.
// =============================================================================

import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_filter.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

final _date = DateFormat('dd/MM/yyyy');
final _dateTime = DateFormat('HH:mm dd/MM/yyyy');

/// `29/10/2026`.
String formatDate(DateTime date) => _date.format(date);

/// `14:05 29/10/2026`.
String formatDateTime(DateTime dateTime) => _dateTime.format(dateTime);

/// Hạn chót, dùng chữ cho hôm qua, hôm nay, ngày mai.
String formatDueDate(
  Translations t,
  DateTime dueDate, {
  required DateTime now,
}) {
  // So sánh bằng ngày UTC: tránh lệch một ngày vào hôm đổi giờ mùa hè.
  final today = DateTime.utc(now.year, now.month, now.day);
  final due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
  return switch (due.difference(today).inDays) {
    -1 => t.tasks.yesterday,
    0 => t.tasks.today,
    1 => t.tasks.tomorrow,
    _ => formatDate(dueDate),
  };
}

/// Tên độ ưu tiên theo ngôn ngữ đang chọn.
extension TaskPriorityLabel on TaskPriority {
  /// Vd: "Cao" / "High".
  String label(Translations t) => switch (this) {
    TaskPriority.low => t.tasks.priority.low,
    TaskPriority.medium => t.tasks.priority.medium,
    TaskPriority.high => t.tasks.priority.high,
  };
}

/// Tên bộ lọc theo ngôn ngữ đang chọn.
extension TaskFilterLabel on TaskFilter {
  /// Vd: "Chưa xong" / "Active".
  String label(Translations t) => switch (this) {
    TaskFilter.all => t.tasks.filter.all,
    TaskFilter.active => t.tasks.filter.active,
    TaskFilter.completed => t.tasks.filter.completed,
  };
}
