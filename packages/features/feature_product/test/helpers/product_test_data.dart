// Dữ liệu mẫu và mock dùng chung cho test của feature_product.
//
// JSON lấy theo cấu trúc response THẬT của dummyjson, giữ nguyên các "bẫy"
// đã phát hiện khi gọi thử API: `discountPercentage` là số nguyên ở vài sản
// phẩm, `brand` bị thiếu, response chi tiết có rất nhiều trường thừa.
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:feature_product/src/data/datasources/product_remote_data_source.dart';
import 'package:feature_product/src/data/local/product_local_data_source.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/domain/repositories/product_repository.dart';
import 'package:feature_product/src/domain/usecases/product_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRemoteDataSource extends Mock
    implements ProductRemoteDataSource;

class MockProductLocalDataSource extends Mock implements ProductLocalDataSource;

class MockProductRepository extends Mock implements ProductRepository;

class MockGetProductsUseCase extends Mock implements GetProductsUseCase;

class MockGetProductDetailUseCase extends Mock
    implements GetProductDetailUseCase;

class MockAppLogger extends Mock implements AppLogger;

/// Response thật (rút gọn còn 2 sản phẩm) của `GET /products?select=...`.
const productPageJson = <String, Object?>{
  'products': [
    {
      'id': 1,
      'title': 'Essence Mascara Lash Princess',
      'price': 9.99,
      'discountPercentage': 10.48,
      'rating': 2.56,
      'thumbnail': 'https://cdn.dummyjson.com/1/thumbnail.webp',
    },
    {
      'id': 2,
      'title': 'Eyeshadow Palette with Mirror',
      'price': 19.99,
      // Số nguyên, không phải 5.0: API thật trả như vậy ở vài sản phẩm.
      'discountPercentage': 5,
      'rating': 2.86,
      'thumbnail': 'https://cdn.dummyjson.com/2/thumbnail.webp',
    },
  ],
  'total': 194,
  'skip': 0,
  'limit': 2,
};

/// Response thật (rút gọn) của `GET /products/{id}`: KHÔNG có `brand`, có
/// nhiều trường app không dùng.
const productDetailJson = <String, Object?>{
  'id': 2,
  'title': 'Eyeshadow Palette with Mirror',
  'description': 'Bảng phấn mắt có gương.',
  'category': 'beauty',
  'price': 19.99,
  'discountPercentage': 5,
  'rating': 2.86,
  'stock': 34,
  'tags': ['beauty', 'eyeshadow'],
  'sku': 'MVCZWFPO',
  'weight': 2,
  'dimensions': {'width': 12.42, 'height': 8.63, 'depth': 29.13},
  'reviews': [
    {'rating': 4, 'comment': 'Great!'},
  ],
  'images': [
    'https://cdn.dummyjson.com/2/1.webp',
    'https://cdn.dummyjson.com/2/2.webp',
  ],
  'thumbnail': 'https://cdn.dummyjson.com/2/thumbnail.webp',
};

/// Tạo sản phẩm rút gọn mẫu với mã [id].
ProductSummary summary(int id) => ProductSummary(
  id: id,
  title: 'Sản phẩm $id',
  price: 10,
  discountPercentage: 0,
  rating: 4,
  thumbnailUrl: 'https://cdn.test/$id.webp',
);

/// Tạo một trang gồm các sản phẩm có mã [ids].
ProductPage page(
  List<int> ids, {
  int total = 100,
  int skip = 0,
  bool isFromCache = false,
}) => ProductPage(
  items: [for (final id in ids) summary(id)],
  total: total,
  skip: skip,
  isFromCache: isFromCache,
);

/// Chi tiết sản phẩm mẫu.
const productDetail = ProductDetail(
  id: 2,
  title: 'Eyeshadow Palette with Mirror',
  description: 'Bảng phấn mắt có gương.',
  price: 19.99,
  discountPercentage: 5,
  rating: 2.86,
  stock: 34,
  category: 'beauty',
  imageUrls: [
    'https://cdn.dummyjson.com/2/1.webp',
    'https://cdn.dummyjson.com/2/2.webp',
  ],
);

/// Tạo DioException có response với mã [statusCode].
DioException httpError(int statusCode) {
  final request = RequestOptions(path: '/test');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: request,
    response: Response<Object?>(
      requestOptions: request,
      statusCode: statusCode,
    ),
  );
}

/// Tạo DioException mất kết nối.
DioException connectionError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/test'),
  reason: 'offline',
);
