import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'controllers/task_controller.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'services/task_storage_service.dart';

/// Root widget: creates the task controller and the router, and configures
/// the theme.
class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    required this.storage,
    this.initialLocation = AppRoutes.tasks,
  });

  final TaskStorageService storage;

  /// The first URL to show. Tests change it to simulate opening the app
  /// from a deep link such as `/tasks/123`.
  final String initialLocation;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  // Material 3 generates the whole color palette from this one color.
  static const Color _seedColor = Color(0xFF4F46E5);

  // Lets us show a SnackBar without a BuildContext: a save can fail after
  // the page that started it has already closed.
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late final TaskController _taskController;

  // Created once in initState, not in build: build can run many times, and
  // a new GoRouter would lose the current page stack.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _taskController = TaskController(
      storage: widget.storage,
      onSaveError: _showSaveError,
    );
    _taskController.load();
    _router = createAppRouter(
      taskController: _taskController,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _showSaveError() {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Không thể lưu thay đổi. Vui lòng thử lại.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // MaterialApp.router: the router decides which pages to show, from the
    // current URL, instead of a fixed `home` widget.
    return MaterialApp.router(
      routerConfig: _router,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      // Built-in widgets (date picker, dialogs, tooltips) use Vietnamese.
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
