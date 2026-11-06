/// Package `core`: hạ tầng kỹ thuật dùng chung cho toàn app.
///
/// Thuộc tầng 2 (nền tảng). Được import bởi mọi `feature_*` và `main_app`.
/// Chỉ phụ thuộc `shared_domain`, không bao giờ biết tới feature nào.
///
/// Phase 2 sẽ bổ sung: config/flavor, logger (talker), network (dio +
/// interceptor), map lỗi sang `Failure`, storage, module DI nền.
library;
