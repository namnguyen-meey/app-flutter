// TokenStorage lưu trong bộ nhớ, dùng cho test. Dùng bản "fake" thay vì
// mock vì nó có hành vi thật (lưu rồi đọc lại được), test dễ đọc hơn so với
// phải stub từng lời gọi.
import 'package:core/core.dart';

/// [TokenStorage] lưu trong bộ nhớ.
class InMemoryTokenStorage implements TokenStorage {
  /// Tạo storage, có thể nạp sẵn [tokens].
  new([this.tokens]);

  /// Token đang lưu.
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}
