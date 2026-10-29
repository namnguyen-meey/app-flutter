/// Priority levels a task can have.
///
/// This is an "enhanced enum": each value carries extra data ([label]).
enum TaskPriority {
  low('Thấp'),
  medium('Trung bình'),
  high('Cao');

  const TaskPriority(this.label);

  /// Text shown in the UI.
  final String label;
}

/// A single todo item.
///
/// The class is immutable (every field is `final`). To change a task we
/// create a new copy with [copyWith] instead of modifying the old object.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// Creates a brand new task with a generated [id] and the current time.
  factory Task.create({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) {
    final DateTime now = DateTime.now();
    return Task(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
    );
  }

  /// Creates a task from a map produced by [toJson].
  factory Task.fromJson(Map<String, dynamic> json) {
    final String? dueDate = json['dueDate'] as String?;
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      // Fall back to medium if the stored value is unknown.
      priority:
          TaskPriority.values.asNameMap()[json['priority']] ??
          TaskPriority.medium,
      dueDate: dueDate == null ? null : DateTime.parse(dueDate),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;

  /// Deadline (date only), or `null` when the task has no deadline.
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  /// Whether the deadline has passed and the task is still not done.
  ///
  /// [now] can be passed in tests to get a predictable result.
  bool isOverdue({DateTime? now}) {
    final DateTime? due = dueDate;
    if (isCompleted || due == null) {
      return false;
    }
    final DateTime current = now ?? DateTime.now();
    final DateTime today = DateTime(current.year, current.month, current.day);
    return due.isBefore(today);
  }

  /// Returns a copy of this task with the given fields replaced.
  ///
  /// Passing `null` for [dueDate] means "keep the old value", so use
  /// [clearDueDate] to remove the deadline.
  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  /// Converts the task to a map of simple values (String, bool, null)
  /// that can be encoded as JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
