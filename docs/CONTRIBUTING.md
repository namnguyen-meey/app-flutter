# Đóng góp code

Quy trình làm việc chung của team. Mục tiêu: mọi người viết code **giống
nhau**, review nhanh, và `main` lúc nào cũng chạy được.

## 1. Chuẩn bị máy

Làm theo phần **Cài đặt** trong [README](../README.md). Kiểm tra máy đã sẵn
sàng:

```bash
melos bootstrap && melos run analyze && melos run test
```

Cả 3 lệnh xanh thì bắt đầu được.

## 2. Quy trình

```
tạo nhánh từ main -> code + test -> kiểm tra trên máy -> mở PR -> CI xanh + review -> squash merge
```

- **Không push thẳng lên `main`.** Mọi thay đổi đi qua Pull Request.
- PR nhỏ, một mục đích. Dưới ~400 dòng thay đổi (không tính file sinh ra và
  ảnh golden) là dễ review. Tính năng lớn thì chia nhiều PR: domain + data
  trước, UI sau.
- Merge bằng **Squash and merge**: mỗi PR thành một commit trên `main`, lịch
  sử gọn.

### Đặt tên nhánh

`<loại>/<mô-tả-ngắn>`, chữ thường, không dấu:

| Loại | Dùng khi | Ví dụ |
|---|---|---|
| `feature/` | Tính năng mới | `feature/product-category-filter` |
| `fix/` | Sửa lỗi | `fix/token-refresh-loop` |
| `refactor/` | Đổi cấu trúc, không đổi hành vi | `refactor/split-product-repository` |
| `docs/` | Chỉ sửa tài liệu | `docs/bloc-guide-transformers` |
| `chore/` | Cấu hình, CI, nâng version thư viện | `chore/upgrade-flutter-3-48` |

### Commit message

Theo [Conventional Commits](https://www.conventionalcommits.org/). Phần
`type` viết bằng tiếng Anh, phần mô tả viết tiếng Việt:

```
<type>: <mô tả ngắn, thì hiện tại>

<giải thích TẠI SAO, nếu chưa hiển nhiên>
```

`type` gồm: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`,
`perf`. Ví dụ (tình huống giả định, chỉ để minh hoạ):

```
fix: không làm mới token khi request đăng nhập bị 401

Request đăng nhập đánh dấu skipAuth. Trước đây 401 do sai mật khẩu vẫn kích
hoạt làm mới token, rồi làm mới thất bại và đá người dùng ra màn đăng nhập.
```

## 3. Trước khi push

```bash
melos run format     # format code do người viết
melos run analyze    # kiến trúc + lint (giống CI)
melos run test       # unit, widget, golden (giống CI)
```

CI chạy **đúng** các lệnh này (`.github/workflows/ci.yaml`). Trên máy xanh
thì trên CI cũng xanh. Đổi gì liên quan tới luồng chính (đăng nhập, danh
sách, chi tiết) thì chạy thêm integration test trên simulator:

```bash
cd apps/main_app && flutter test integration_test --flavor dev
```

## 4. Quy tắc code

Những gì máy kiểm tra được thì đã có lint và `arch_check` lo. Dưới đây là
những điều **người review** sẽ hỏi.

### Kiến trúc

- Đặt code đúng tầng, đúng package ([ARCHITECTURE.md](ARCHITECTURE.md)).
  Không chắc thì hỏi trước khi viết.
- Feature không import feature khác. Cần dùng chung thì đưa interface vào
  `shared_domain`, hoặc để app nối bằng callback.
- Domain không import Flutter, dio, drift hay package hạ tầng nào.
- Bloc/Cubit theo [BLOC_GUIDE.md](BLOC_GUIDE.md).
- Chỉ gọi `getIt<...>()` ở rìa app (router, bootstrap), không gọi bên trong
  widget hay class.

### Comment và tài liệu

- Comment bằng **tiếng Việt**, giải thích **tại sao** chứ không lặp lại
  code. Không cần `// tăng i lên 1`. Cần: "dùng `droppable` vì bấm 2 lần không
  được gửi 2 request".
- File quan trọng có **header**: làm gì, thuộc tầng/package nào, ai gọi nó.
  Xem các file có sẵn để làm theo.
- Mọi public API có `///` (lint `public_member_api_docs` bắt buộc).
- Đổi hành vi thì cập nhật README của package hoặc tài liệu trong `docs/`
  trong **cùng** PR.

### Giao diện

- Import `package:material_ui/material_ui.dart`, **không** dùng
  `package:flutter/material.dart`.
- Không viết màu cứng (`Color(0xFF...)`), không đặt số khoảng cách tuỳ ý.
  Dùng `context.colorScheme`, `context.appColors`, `AppSpacing`, `AppRadius`.
- Không viết chuỗi hiển thị trong code. Mọi chuỗi đi qua `l10n`
  (`context.t...`). Thêm khoá vào **cả** `vi.i18n.json` và `en.i18n.json`,
  vì thiếu một bên thì không compile được.
- Component dùng lại được thì đưa vào `design_system`, kèm use case trong
  `widgetbook_app`.

### Test

| Thay đổi | Test tối thiểu |
|---|---|
| Use case, repository, mapper | Unit test |
| Bloc/Cubit | `blocTest` cho thành công, lỗi và tình huống đồng thời (nếu có transformer) |
| Màn hình mới | Widget test với Bloc giả (`MockBloc` + `whenListen`) |
| Component trong `design_system` | Widget test; golden test nếu là component quan trọng |
| Sửa bug | Một test tái hiện bug (fail trước khi sửa, pass sau khi sửa) |

## 5. Thêm thư viện

1. Kiểm tra theo mục "Khi muốn thêm thư viện mới" trong
   [PACKAGES.md](PACKAGES.md).
2. `cd <package> && flutter pub add <tên>` (dev: `flutter pub add dev:<tên>`).
   **Không** gõ số phiên bản bằng tay vào `pubspec.yaml`.
3. Commit cả `pubspec.yaml` của package lẫn `pubspec.lock` ở root.
4. Thêm một dòng vào bảng trong `PACKAGES.md`.

## 6. Code sinh ra

- Không bao giờ sửa tay file `*.g.dart`, `*.freezed.dart`, `*.config.dart`,
  `*.module.dart`. Các file này không được commit (đã có trong `.gitignore`).
- Đổi annotation, DTO, bảng drift, bản dịch... thì chạy `melos run gen`.
  Hoặc mở `melos run gen:watch` trong lúc code để tự sinh lại.
- Lỗi lạ sau khi pull code mới: chạy lại `melos bootstrap` (cài dependency
  và sinh lại code).

## 7. Golden test

- Đổi giao diện component **có chủ ý** thì tạo lại ảnh mẫu và commit cùng
  code:
  ```bash
  cd packages/design_system && flutter test --update-goldens test/golden
  ```
- Mở ảnh mới trong `test/golden/goldens/ci/` để kiểm tra trước khi commit.
  Người review cũng xem ảnh trong diff của PR.
- Golden fail mà bạn **không** cố ý đổi giao diện nghĩa là bạn vừa gây ra
  một thay đổi ngoài ý muốn. Xem ảnh so sánh trong `test/golden/failures/`
  (trên CI: artifact `golden-failures`).

## 8. Bí mật và cấu hình

- Không commit file `env/.env.<flavor>` (chỉ commit `*.example`).
- Không đặt secret thật (API key bí mật, mật khẩu, token) vào app, kể cả qua
  `.env`: mọi giá trị build vào app đều trích xuất được.
- Không commit file cấu hình tự viết cho Firebase/Sentry. Xem
  [OBSERVABILITY.md](OBSERVABILITY.md).

## 9. Review

**Người mở PR:**
- Điền mẫu PR (`.github/pull_request_template.md`): làm gì, tại sao, test
  thế nào, ảnh chụp nếu đổi UI.
- Tự review diff một lượt trước khi nhờ người khác.

**Người review:**
- Ưu tiên: đúng hành vi → đúng kiến trúc → có test → dễ đọc. Chuyện format
  và lint đã có máy lo.
- Góp ý cụ thể, giải thích lý do. Ghi rõ góp ý nào **bắt buộc** sửa, góp ý
  nào chỉ là gợi ý (ví dụ thêm tiền tố `nit:`).
- Đổi ảnh golden: mở ảnh, xác nhận thay đổi là cố ý.

## 10. Nâng phiên bản Flutter

1. Đổi `FLUTTER_VERSION` trong `.github/workflows/ci.yaml` và phần **Yêu
   cầu** của README trong **cùng một** PR.
2. `melos bootstrap`, `melos run analyze`, `melos run test` và chạy
   integration test.
3. Golden lệch do Flutter đổi cách vẽ thì tạo lại ảnh và ghi rõ trong PR.
