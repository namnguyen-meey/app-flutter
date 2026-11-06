// =============================================================================
// stream_listenable.dart: biến một Stream thành Listenable cho go_router.
//
// Thuộc: apps/main_app/router.
// Được dùng bởi: app.dart, truyền `StreamListenable(authBloc.stream)` vào
// `refreshListenable` của GoRouter.
//
// go_router nhận `Listenable` (kiểu của Flutter) để biết khi nào chạy lại
// redirect, còn Bloc phát trạng thái qua `Stream`. Class nhỏ này là cầu nối.
// =============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Báo cho người nghe mỗi khi stream truyền vào phát giá trị mới.
class StreamListenable extends ChangeNotifier {
  /// Bắt đầu lắng nghe [stream].
  new(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
