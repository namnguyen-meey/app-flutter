// =============================================================================
// app_spacing.dart: token khoảng cách và bo góc.
//
// Thuộc: design_system/tokens.
// Được dùng bởi: component của design_system và UI của các feature.
//
// Tại sao không viết thẳng `EdgeInsets.all(16)`? Con số rải rác khắp nơi sẽ
// lệch dần (15, 16, 18...) và giao diện mất nhất quán. Dùng token thì chỉ có
// một thang đo (bội số của 4) và đổi một chỗ là cả app đổi theo.
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Thang khoảng cách, bội số của 4.
abstract final class AppSpacing {
  /// 4
  static const double xs = 4;

  /// 8
  static const double sm = 8;

  /// 12
  static const double md = 12;

  /// 16: khoảng cách mặc định giữa các khối.
  static const double lg = 16;

  /// 24
  static const double xl = 24;

  /// 32
  static const double xxl = 32;

  /// Lề mặc định của một trang.
  static const EdgeInsets page = EdgeInsets.all(lg);
}

/// Thang bo góc.
abstract final class AppRadius {
  /// 8: chip, nhãn nhỏ.
  static const double sm = 8;

  /// 12: nút, ô nhập liệu.
  static const double md = 12;

  /// 16: card.
  static const double lg = 16;

  /// [BorderRadius] với bán kính [sm].
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// [BorderRadius] với bán kính [md].
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] với bán kính [lg].
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}
