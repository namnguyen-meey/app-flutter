import 'package:flutter/material.dart';

import 'app.dart';
import 'services/task_storage_service.dart';

// animal.dart
abstract class Animal {
  void eat() {
    print('Eating...');
  }
}

class Dog extends Animal {}

void main() {
  runApp(TodoApp(storage: TaskStorageService()));
}
