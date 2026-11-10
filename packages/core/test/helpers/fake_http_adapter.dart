// Adapter HTTP giả cho dio: thay phần kết nối mạng thật bằng một hàm trả lời
// do test tự viết. Nhờ vậy test chạy được mọi interceptor y như thật mà
// không cần internet hay server giả.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Hàm quyết định server giả trả về gì cho một request.
typedef FakeServer = Future<ResponseBody> Function(RequestOptions request);

/// [HttpClientAdapter] trả lời bằng [server] và ghi lại mọi request nhận được.
class FakeHttpAdapter implements HttpClientAdapter {
  /// Tạo adapter giả.
  new(this.server);

  /// Hàm trả lời request.
  FakeServer server;

  /// Mọi request đã đi tới "mạng", theo thứ tự.
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return server(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Tạo response JSON với mã [statusCode].
ResponseBody jsonResponse(Object? data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
