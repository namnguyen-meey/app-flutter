import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../models/task_summary.dart';
import '../services/task_storage_service.dart';

/// Whether the saved tasks have been read from the device yet.
enum TaskLoadStatus { loading, ready, failed }

/// Holds the task list for the whole app and saves every change.
///
/// Before GoRouter, the list lived in HomeScreen's State. Now the list,
/// detail, edit and statistics pages are separate routes, and a deep link
/// such as `/tasks/123` can open the detail page without the list page ever
/// being built. So the list moved here, above the router, and every page
/// receives the same controller.
///
/// [ChangeNotifier] is part of Flutter (no package needed): after a change
/// we call [notifyListeners], and every `ListenableBuilder` listening to
/// this object rebuilds.
class TaskController extends ChangeNotifier {
  /// Called as `TaskController(storage: ...)`: Dart drops the `_` from the
  /// name of a private named parameter.
  TaskController({required this._storage, this.onSaveError});

  final TaskStorageService _storage;

  /// Called when a change could not be saved, so the UI can tell the user.
  final VoidCallback? onSaveError;

  final ValueNotifier<TaskLoadStatus> _loadStatus = ValueNotifier(
    TaskLoadStatus.loading,
  );
  List<Task> _tasks = [];
  TaskSummary? _summary;
  bool _isDisposed = false;

  /// Changes only when loading starts, succeeds or fails, not on every
  /// edit. The router listens to it to decide when to leave `/loading`.
  ValueListenable<TaskLoadStatus> get loadStatus => _loadStatus;

  /// A read-only view of the tasks. Changes must go through the methods
  /// below, so they are always saved.
  List<Task> get tasks => UnmodifiableListView(_tasks);

  /// Statistics for the current list, computed once per change.
  TaskSummary get summary => _summary ??= TaskSummary.fromTasks(_tasks);

  /// The task with [id], or `null` if there is none.
  Task? findById(String id) {
    return _tasks.where((task) => task.id == id).firstOrNull;
  }

  Future<void> load() async {
    _loadStatus.value = TaskLoadStatus.loading;

    try {
      final List<Task> tasks = await _storage.loadTasks();
      // The app may have been closed while we were waiting (like checking
      // `mounted` in a State).
      if (_isDisposed) {
        return;
      }
      _tasks = tasks;
      _summary = null;
      notifyListeners();
      _loadStatus.value = TaskLoadStatus.ready;
    } catch (error) {
      debugPrint('Failed to load tasks: $error');
      if (_isDisposed) {
        return;
      }
      _loadStatus.value = TaskLoadStatus.failed;
    }
  }

  void addTask(Task task) {
    _update(() => _tasks.insert(0, task));
  }

  /// Replaces the task that has the same id as [updatedTask].
  void updateTask(Task updatedTask) {
    _update(() {
      final int index = _tasks.indexWhere((item) => item.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    });
  }

  void toggleCompleted(Task task) {
    updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  void deleteTask(String id) {
    _update(() => _tasks.removeWhere((task) => task.id == id));
  }

  /// The single place where the list changes: apply the change, tell the
  /// listeners, then save the new list to the device.
  void _update(VoidCallback change) {
    // Never overwrite saved data that we could not read.
    if (_loadStatus.value != TaskLoadStatus.ready) {
      return;
    }
    change();
    _summary = null;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      await _storage.saveTasks(_tasks);
    } catch (error) {
      debugPrint('Failed to save tasks: $error');
      if (!_isDisposed) {
        onSaveError?.call();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadStatus.dispose();
    super.dispose();
  }
}
