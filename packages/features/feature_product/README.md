# feature_product

> Tầng 3 · Feature · Flutter package

Danh sách sản phẩm có phân trang vô hạn, kéo để làm mới, skeleton khi tải,
tìm kiếm có debounce, trạng thái lỗi/rỗng, cache offline bằng drift; màn chi
tiết sản phẩm. Dữ liệu từ API dummyjson (`/products`, `/products/search`,
`/products/{id}`).

| | |
|---|---|
| **Phụ thuộc vào** | `core`, `design_system`, `l10n`, `shared_domain` |
| **Được dùng bởi** | `main_app` (router + DI) |
| **Không được phụ thuộc** | feature khác, router (điều hướng qua callback) |

## Cấu trúc

```
lib/src/
├── data/
│   ├── datasources/   # ProductRemoteDataSource (retrofit, dùng `select=` cho nhẹ)
│   ├── dtos/          # ProductSummaryDto, ProductDetailDto, ProductPageDto
│   ├── local/         # ProductDatabase (drift) + ProductLocalDataSource
│   └── repositories/  # ProductRepositoryImpl: mạng trước, lỗi mạng thì dùng cache
├── domain/            # ProductSummary, ProductDetail, ProductPage, use case
├── presentation/
│   ├── list/          # ProductListBloc + ProductListPage
│   ├── detail/        # ProductDetailCubit + ProductDetailPage
│   └── widgets/       # định dạng giá/đánh giá theo ngôn ngữ
└── di/
```

## Những điểm đáng học

**Bloc hay Cubit?** Danh sách dùng **Bloc**: có 4 loại event, mỗi loại một
luật xử lý đồng thời riêng (transformer). Chi tiết dùng **Cubit**: chỉ có một
hành động là tải, gọi hàm trực tiếp là đủ.

| Event | Transformer | Vì sao |
|---|---|---|
| `ProductListQueryChanged` | debounce 400ms + `restartable` | Chờ ngừng gõ mới tìm; gõ tiếp thì huỷ lần tìm cũ |
| `ProductListNextPageRequested` | `droppable` | Đang tải trang thì bỏ qua yêu cầu trùng |
| `ProductListRefreshed` | `restartable` | Kéo làm mới lần nữa thì huỷ lần cũ |

**Chống kết quả lỗi thời.** Các loại event khác nhau vẫn chạy song song. Ví
dụ đang tải trang 3 thì người dùng gõ từ khoá mới: kết quả trang 3 về sau
không được nối vào danh sách mới. Bloc giữ một bộ đếm `_generation` và bỏ mọi
kết quả mang "thế hệ" cũ (có test riêng cho tình huống này).

**Cache offline (network-first).** Danh sách mặc định tải được thì ghi vào
SQLite. Mất mạng ở trang đầu thì trả dữ liệu đã lưu kèm cờ `isFromCache`, và
UI hiện dải "offline". Ghi cache lỗi KHÔNG làm hỏng request đã thành công.

**Phân trang với infinite_scroll_pagination 5.** Thư viện không tự tải dữ
liệu: `PagedGridView` nhận `PagingState` (dựng từ state của Bloc) và gọi
`fetchNextPage` khi cuộn gần cuối. Mọi indicator (skeleton, lỗi, rỗng, hết)
lấy từ `design_system`. Thư viện vẫn dùng `flutter/material.dart` bản cũ
nhưng phần lõi không dùng API riêng của Material, nên không cần
`MaterialUiCompatibilityBridge`.

**Dữ liệu thật có "bẫy"** (đã kiểm tra bằng API): `brand` thiếu ở gần một
nửa sản phẩm, `discountPercentage` đôi khi là số nguyên. Cả hai đều có trong
dữ liệu test.
