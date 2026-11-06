// =============================================================================
// app.dart: widget gốc của ứng dụng.
//
// Thuộc: apps/main_app (tầng app).
// Được tạo bởi: bootstrap.dart (bản thật) và widget test.
//
// Phase 2: màn hình tạm hiển thị cấu hình flavor để kiểm tra DI.
// Phase 3: thay bằng theme của design_system và đa ngôn ngữ.
// Phase 4: thay `home` bằng router (go_router) có guard đăng nhập.
// =============================================================================

import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Widget gốc của app.
class App extends StatelessWidget {
  /// Tạo app với cấu hình [config].
  const new({required this.config, super.key});

  /// Cấu hình của flavor đang chạy.
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      // Dải băng ở góc màn hình với bản không phải prod. Giúp tester và dev
      // không bao giờ nhầm đang dùng bản dev hay bản thật.
      builder: (context, child) {
        final page = child ?? const SizedBox.shrink();
        if (config.isProduction) return page;
        return Banner(
          message: config.flavor.name.toUpperCase(),
          location: BannerLocation.topEnd,
          child: page,
        );
      },
      home: _FlavorInfoPage(config: config),
    );
  }
}

/// Màn hình tạm của Phase 2: hiển thị cấu hình flavor đang chạy.
class _FlavorInfoPage extends StatelessWidget {
  const new({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(config.appName)),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Flavor'),
            subtitle: Text(config.flavor.name),
          ),
          ListTile(title: const Text('API'), subtitle: Text(config.apiBaseUrl)),
          ListTile(
            title: const Text('Log'),
            subtitle: Text(config.enableLogs ? 'Bật' : 'Tắt'),
          ),
          ListTile(
            title: const Text('Thời hạn access token'),
            subtitle: Text('${config.accessTokenLifetime.inMinutes} phút'),
          ),
        ],
      ),
    );
  }
}
