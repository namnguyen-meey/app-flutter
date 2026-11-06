import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/services/task_storage_service.dart';

/// In-memory replacement for [TaskStorageService] used in tests.
///
/// `implements` means we promise to provide the same public methods as the
/// real service, so TaskController cannot tell the difference.
class FakeTaskStorageService implements TaskStorageService {
  FakeTaskStorageService({
    List<Task> initialTasks = const [],
    this.failOnLoad = false,
    this.failOnSave = false,
  }) : savedTasks = List.of(initialTasks);

  /// When true, [loadTasks] throws to simulate corrupted data.
  final bool failOnLoad;

  /// When true, [saveTasks] throws to simulate a full or broken storage.
  final bool failOnSave;

  /// What is currently "saved on the device".
  List<Task> savedTasks;
  int saveCount = 0;

  @override
  Future<List<Task>> loadTasks() async {
    if (failOnLoad) {
      throw const FormatException('Corrupted data');
    }
    return List.of(savedTasks);
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    if (failOnSave) {
      throw StateError('Storage is full');
    }
    saveCount++;
    savedTasks = List.of(tasks);
  }
}
