import 'package:flutter/material.dart';

import 'app.dart';
import 'services/task_storage_service.dart';

void main() {
  runApp(TodoApp(storage: TaskStorageService()));
}
