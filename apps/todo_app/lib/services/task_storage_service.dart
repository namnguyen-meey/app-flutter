import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// Saves and loads the task list on the device.
///
/// The whole list is stored as one JSON string under a single key. This is
/// simple and fast enough for a personal todo list with hundreds of tasks.
class TaskStorageService {
  static const String _tasksKey = 'tasks';

  // `late` creates the object on first use, when the app is already
  // running and the plugin is ready.
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// Reads all saved tasks. Returns an empty list on the first launch.
  ///
  /// Throws if the storage cannot be read or the data is corrupted.
  Future<List<Task>> loadTasks() async {
    final String? jsonString = await _preferences.getString(_tasksKey);
    if (jsonString == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Replaces the saved list with [tasks].
  Future<void> saveTasks(List<Task> tasks) async {
    final String jsonString = jsonEncode(
      tasks.map((task) => task.toJson()).toList(),
    );
    await _preferences.setString(_tasksKey, jsonString);
  }
}
