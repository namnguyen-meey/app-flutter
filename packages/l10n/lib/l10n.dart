/// Package `l10n`: đa ngôn ngữ (vi, en) dùng slang.
///
/// Thuộc tầng 2 (nền tảng). Được import bởi mọi `feature_*` và `main_app`.
/// Phụ thuộc `shared_domain` để chuyển `Failure` thành câu thông báo theo
/// ngôn ngữ đang chọn.
///
/// Phase 3 sẽ bổ sung: file dịch vi/en, code sinh bởi slang, extension
/// `Failure` -> thông báo.
library;
