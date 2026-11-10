// Widget test màn danh sách sản phẩm với Bloc giả: vẽ đúng theo từng state
// và gửi đúng event/callback khi thao tác.
import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_product/src/presentation/list/product_list_bloc.dart';
import 'package:feature_product/src/presentation/list/product_list_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/product_test_data.dart';

class _MockProductListBloc extends MockBloc<ProductListEvent, ProductListState>
    implements ProductListBloc;

void main() {
  late _MockProductListBloc bloc;
  late List<int> tappedIds;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.vi);
    bloc = _MockProductListBloc();
    tappedIds = [];
  });

  Future<void> pumpPage(WidgetTester tester, ProductListState state) async {
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider<ProductListBloc>.value(
            value: bloc,
            child: ProductListPage(onProductTap: tappedIds.add),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('có sản phẩm -> hiển thị thẻ; bấm -> gọi onProductTap', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ProductListState(
        items: page([1, 2]).items,
        hasLoadedFirstPage: true,
        hasMore: false,
      ),
    );

    expect(find.byType(ProductCard), findsNWidgets(2));
    await tester.tap(find.text('Sản phẩm 2'));
    expect(tappedIds, [2]);
  });

  testWidgets('đang tải trang đầu -> hiện skeleton, không lỗi layout', (
    tester,
  ) async {
    // Lần đầu skeleton dùng GridView(shrinkWrap) bị lỗi "does not support
    // returning intrinsic dimensions" khi nằm trong SliverFillRemaining của
    // thư viện phân trang. Test này giữ cho lỗi đó không quay lại.
    await pumpPage(tester, const ProductListState(isLoading: true));

    expect(tester.takeException(), isNull);
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(6));
  });

  testWidgets('gõ vào ô tìm kiếm -> gửi ProductListQueryChanged', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const ProductListState(hasLoadedFirstPage: true, hasMore: false),
    );

    await tester.enterText(find.byType(TextField), 'phone');

    verify(() => bloc.add(const ProductListQueryChanged('phone'))).called(1);
  });

  testWidgets('tìm không có kết quả -> thông báo kèm từ khoá', (tester) async {
    await pumpPage(
      tester,
      const ProductListState(
        query: 'xyz',
        hasLoadedFirstPage: true,
        hasMore: false,
      ),
    );

    expect(find.text('Không có sản phẩm nào khớp với “xyz”.'), findsOneWidget);
  });

  testWidgets('trang đầu lỗi -> màn lỗi theo ngôn ngữ, bấm thử lại', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const ProductListState(failure: ConnectionFailure()),
    );

    expect(
      find.text('Không có kết nối mạng. Vui lòng kiểm tra và thử lại.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Thử lại'));
    verify(() => bloc.add(const ProductListRefreshed())).called(1);
  });

  testWidgets('dữ liệu từ cache -> hiện dải "offline"', (tester) async {
    await pumpPage(
      tester,
      ProductListState(
        items: page([1]).items,
        hasLoadedFirstPage: true,
        hasMore: false,
        isFromCache: true,
      ),
    );

    expect(find.text('Đang offline, hiển thị dữ liệu đã lưu'), findsOneWidget);
  });
}
