# Verification - 09/10/2026

## Đã thực hiện

| Kiểm tra | Kết quả | Phạm vi |
|---|---|---|
| Flutter analyze trong PowerShell thông thường | Không có issue | Log người dùng |
| Flutter test trong PowerShell thông thường | 12/12 đạt | Log người dùng |
| Build APK debug | BUILD SUCCESSFUL trong 10m 33s | Log Gradle và file APK trực tiếp |
| APK release 1.0.0 | 92.399.631 byte; ký riêng v2 hợp lệ | File thực tế; fingerprint trong RELEASE.md |
| apksigner verify | Đạt, chữ ký v2, Android Debug | APK thực tế |
| Test bản debug | Người dùng báo OK | Chưa nhận checklist chi tiết từng tính năng |
| Phân tích parser bằng DartPad Dart 3.13.5 | Không có issue | Mã parser gốc |
| Biên dịch parser bằng DartPad compileNewDDC, chạy SDK JS chính thức trên Node 24 | 10/10 đạt | Harness `tools/parser_portable_test.dart`, không dùng bản dịch logic sang JS |
| Parse cú pháp tree-sitter và XML Android | Đạt | Không thay thế Flutter analyzer/type checking toàn app |
| Phân tích/biên dịch browser preview bằng DartPad | Không có issue; biên dịch thành công | Giao diện/model/parser/chart/provider gốc; native services thay bằng adapter mẫu |
| Chrome headless rendering | Đạt ở viewport 320/412/600 px | Không phát hiện Flutter runtime error trong các lượt này |
| Review chưa tick xác nhận | Không gọi save | Fake repository trong browser preview |
| Review đã tick xác nhận | Gọi save đúng 1 lần, 150.000 đ | Fake repository trong browser preview |
| Theme/history screenshots | Tạo được | Flutter web preview với 5 giao dịch mẫu; tổng 430.000 đ |

Các adapter browser chỉ dùng cho xác minh hình thức/luồng form; không nằm trong mã native `lib/`. Screenshot thiếu ảnh hóa đơn thật vì không thực hiện OCR native trong browser.

## Chưa thực hiện

- Native integration test trên thiết bị và kiểm thử lại bản release sau tối ưu R8.
- Camera permission, flash/focus, lifecycle, crop, ML Kit nhận diện ảnh thật/offline/latency trên Android.
- SQLite CRUD, persistence sau restart và cache ảnh/thumbnail trên thiết bị.
- Checklist test release trên điện thoại, video demo và xuất bản repository/Release.

Nguyên nhân: SDK tải được nhưng Dart Windows trong sandbox không canonicalize được đường dẫn executable/source (`OS error 5`, `Platform.resolvedExecutable` trả null). Đã thử hai bản Flutter, quyền đọc SDK trực tiếp và launcher thông thường; lỗi vẫn xuất hiện trước khi Flutter khởi động. Sau đó người dùng chạy trong PowerShell thông thường: analyze và 12 test đã pass; log Gradle xác nhận build debug thành công. Các kết quả sandbox trước đó vẫn được phân biệt với kiểm tra native.

## Log parser thực chạy

```text
PASS: Vietnamese total versus subtotal/cash/change
PASS: Merchant and valid date
PASS: English total and comma groups
PASS: Split total label
PASS: Reject impossible calendar date
PASS: Exclude phone and invoice
PASS: Ambiguous total warns
PASS: Empty receipt
PASS: Reject invalid money
PASS: Accept VND formats
RESULT: 10/10 checks passed
```
