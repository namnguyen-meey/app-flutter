// Smoke test cho catalog: mở TỪNG use case (lấy từ cây `directories` do
// generator sinh ra) ở cả theme sáng và tối, kiểm tra hai điều:
//   1. Không có lỗi khi dựng (ví dụ: thiếu theme material_ui, knob sai kiểu).
//   2. Đúng component của use case đó thực sự được dựng.
//
// Vì duyệt cây sinh ra nên use case mới tự động được test, không cần viết
// thêm gì. Đây là lý do repo cho widgetbook_app có test dù chỉ là công cụ:
// catalog hỏng thì designer/QA mất công cụ làm việc mà không ai biết.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_app/main.dart';
import 'package:widgetbook_app/main.directories.g.dart';
import 'package:widgetbook_app/src/catalog_setup.dart';

/// Use case kèm tên component chứa nó.
typedef _CatalogEntry = ({String path, String component});

/// Duyệt cây [nodes] và trả về mọi use case.
List<_CatalogEntry> _collectUseCases(List<WidgetbookNode> nodes) {
  // WidgetbookRoot gắn `parent` cho từng node, nhờ đó `path` mới đúng.
  final root = WidgetbookRoot(children: nodes);
  return [
    for (final useCase in root.leaves.whereType<WidgetbookUseCase>())
      (path: useCase.path, component: useCase.parent!.name),
  ];
}

void main() {
  final entries = _collectUseCases(directories);

  test('catalog có đủ component của design system', () {
    final components = entries.map((e) => e.component).toSet();
    expect(
      components,
      containsAll(<String>[
        'AppButton',
        'AppTextField',
        'AppNetworkImage',
        'ProductCard',
        'AppLoadingIndicator',
        'AppSkeleton',
        'AppErrorView',
        'AppEmptyView',
      ]),
    );
  });

  for (final theme in catalogThemes) {
    group('theme ${theme.name}', () {
      for (final entry in entries) {
        testWidgets('mở được ${entry.path}', (tester) async {
          // Catalog thiết kế cho màn hình máy tính: dùng cửa sổ đủ rộng để
          // giao diện của widgetbook không bị tràn.
          tester.view
            ..physicalSize = const Size(1600, 1000)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final route = Uri(
            path: '/',
            queryParameters: {
              'path': entry.path,
              // Nhóm tham số của ThemeAddon, cùng định dạng widgetbook dùng
              // trên thanh địa chỉ: theme={name:Tối}.
              'theme': FieldCodec.encodeQueryGroup({'name': theme.name}),
            },
          ).toString();
          await tester.pumpWidget(WidgetbookApp(initialRoute: route));
          // Chỉ pump vài khung hình, không dùng pumpAndSettle: vòng xoay
          // đang tải và hiệu ứng skeleton chạy mãi nên không bao giờ "settle".
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(
            find.byWidgetPredicate(
              (widget) => widget.runtimeType.toString() == entry.component,
            ),
            findsWidgets,
            reason: 'Use case ${entry.path} phải dựng ${entry.component}',
          );
          // Theme của material_ui đã tới được component.
          final context = tester.element(
            find
                .byWidgetPredicate(
                  (widget) => widget.runtimeType.toString() == entry.component,
                )
                .first,
          );
          expect(Theme.of(context).brightness, theme.data.brightness);
        });
      }
    });
  }
}
