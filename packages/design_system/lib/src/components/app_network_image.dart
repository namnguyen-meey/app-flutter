// =============================================================================
// app_network_image.dart: ảnh từ mạng có cache, ô chờ và ô lỗi thống nhất.
//
// Thuộc: design_system/components.
// Được dùng bởi: ProductCard, màn chi tiết sản phẩm.
//
// Tại sao bọc cached_network_image thay vì để feature dùng trực tiếp?
//   - Ô chờ/ô lỗi giống nhau ở mọi nơi.
//   - Feature không phụ thuộc thư viện ảnh: muốn đổi thư viện thì chỉ sửa
//     file này.
// =============================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:material_ui/material_ui.dart';

/// Ảnh tải từ [url], được cache trên máy sau lần tải đầu.
class AppNetworkImage extends StatelessWidget {
  /// Tạo ảnh mạng.
  const new({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    super.key,
  });

  /// Địa chỉ ảnh.
  final String url;

  /// Chiều rộng.
  final double? width;

  /// Chiều cao.
  final double? height;

  /// Cách co giãn ảnh vào khung.
  final BoxFit fit;

  /// Bo góc (tuỳ chọn).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    // URL rỗng (vd: dữ liệu giả của skeleton): hiện ô chờ luôn, không gọi
    // mạng với một địa chỉ chắc chắn lỗi.
    if (url.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const _ImageStatus(icon: Icons.image_outlined),
      );
    }

    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      // `_` là wildcard (Dart 3.7+): dùng được nhiều lần cho tham số không
      // cần tới.
      placeholder: (_, _) => const _ImageStatus(icon: Icons.image_outlined),
      errorWidget: (_, _, _) =>
          const _ImageStatus(icon: Icons.broken_image_outlined),
    );

    final radius = borderRadius;
    return radius == null
        ? image
        : ClipRRect(borderRadius: radius, child: image);
  }
}

/// Ô nền xám kèm icon, dùng khi ảnh đang tải hoặc tải lỗi.
class _ImageStatus extends StatelessWidget {
  const new({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, color: context.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
