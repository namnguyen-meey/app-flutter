# feature_auth

> Tầng 3 · Feature · Flutter package

Đăng nhập bằng API dummyjson, lưu token an toàn, tự làm mới token khi hết
hạn, giữ trạng thái đăng nhập khi mở lại app (kể cả khi offline). Cài đặt
interface `AuthSession` của `shared_domain` để router và các feature khác
dùng mà không cần import package này.

Tài khoản thử của dummyjson: `emilys` / `emilyspass` (màn đăng nhập có nút
điền sẵn).

| | |
|---|---|
| **Phụ thuộc vào** | `core`, `design_system`, `l10n`, `shared_domain` |
| **Được dùng bởi** | `main_app` (router + DI) |
| **Không được phụ thuộc** | feature khác |

## Cấu trúc

```
lib/
├── feature_auth.dart          # barrel: chỉ export thứ main_app cần
└── src/
    ├── data/
    │   ├── datasources/       # AuthRemoteDataSource (retrofit), AuthLocalDataSource
    │   ├── dtos/              # UserDto, LoginRequestDto, LoginResponseDto...
    │   ├── repositories/      # AuthRepositoryImpl (nguồn sự thật của trạng thái đăng nhập)
    │   └── auth_token_refresher.dart   # cài đặt TokenRefresher của core
    ├── domain/                # Dart THUẦN: không Flutter, không dio, không DI
    │   ├── repositories/      # AuthRepository (interface)
    │   └── usecases/          # LoginUseCase, RestoreSessionUseCase, LogoutUseCase
    ├── presentation/
    │   ├── auth/              # AuthBloc: trạng thái đăng nhập toàn cục
    │   └── login/             # LoginBloc + LoginPage: form đăng nhập
    └── di/                    # module DI (đăng ký cả use case của domain)
```

## Luồng chính

```
Mở app ──► AuthStarted ──► RestoreSessionUseCase ──► AuthRepositoryImpl
                                                       ├─ không có token      ─► Unauthenticated
                                                       ├─ GET /auth/me OK     ─► Authenticated
                                                       ├─ 401 (refresh hỏng)  ─► Unauthenticated
                                                       └─ mất mạng + có cache ─► Authenticated (offline)

Đăng nhập ──► LoginBloc ──► LoginUseCase ──► POST /auth/login ──► lưu token + user
                                                                 ──► Authenticated
                                                                 ──► router tự chuyển màn
```

Trạng thái đăng nhập có **một nguồn sự thật**: `AuthRepositoryImpl`. AuthBloc
chỉ phát lại trạng thái đó cho UI. Vì vậy dù đăng xuất từ đâu (màn cài đặt,
hay hết phiên do `AuthInterceptor` của core), router đều phản ứng giống nhau.

## Điểm đáng chú ý

- **Hai Dio:** việc làm mới token dùng Dio không có AuthInterceptor
  (`DioName.unauthenticated`), để tránh vòng phụ thuộc DI và vòng lặp vô hạn.
- **Lỗi 400 khi đăng nhập** được chuyển thành `InvalidCredentialsFailure` ngay
  trong repository, vì đó là ý nghĩa nghiệp vụ của riêng feature này.
- **Không lộ mật khẩu:** `UserDto` bỏ qua trường `password` mà `/auth/me` trả
  về; `LoginState`, `LoginPasswordChanged` và `LoginRequestDto` che mật khẩu
  trong `toString()` (vì BlocObserver ghi log mọi event/state).
- **Chống gửi 2 lần:** `LoginSubmitted` dùng transformer `droppable()` của
  bloc_concurrency, cộng với nút bị khoá khi đang tải.
