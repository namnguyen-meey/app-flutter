import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/services/task_storage_service.dart';

/// In-memory replacement for [TaskStorageService] used in widget tests.
///
/// `implements` means we promise to provide the same public methods as the
/// real service, so HomeScreen cannot tell the difference.
class FakeTaskStorageService implements TaskStorageService {
  FakeTaskStorageService({
    List<Task> initialTasks = const [],
    this.failOnLoad = false,
  }) : savedTasks = List.of(initialTasks);

  /// When true, [loadTasks] throws to simulate corrupted data.
  final bool failOnLoad;

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
    saveCount++;
    savedTasks = List.of(tasks);
  }
}
