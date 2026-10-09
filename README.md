# Receipt Lens - Mini-Project 3

**Sinh viên:** Trần Thanh Quý  
**Mã sinh viên:** 23IT228  
**Môn học:** Cross-Platform Mobile App Development - VKU

Ứng dụng Flutter quản lý chi tiêu từ hóa đơn trên Android. Luồng chính:
**Camera / Gallery → Crop → ML Kit Latin OCR → Regex → Review → SQLite → Riverpod → CustomPainter**.

## Bản bàn giao

- APK release ký riêng: [`releases/app-release.apk`](releases/app-release.apk), **92.399.631 byte**; chữ ký APK v2 đã xác minh bằng apksigner.
- `flutter analyze`: không có issue. `flutter test`: **12/12 đạt**, theo log chạy trong PowerShell thông thường.
- Người dùng đã báo test bản debug OK. Bản release cần kiểm thử lại camera/OCR và lưu dữ liệu trên Android.
- Báo cáo 4 trang: [`docs/Mini-Project-3-Report-Draft.pdf`](docs/Mini-Project-3-Report-Draft.pdf). Đã điền sinh viên; ảnh hiện là Flutter web preview và cần thay bằng ảnh thiết bị trước khi nộp.
- Xem [`docs/SUBMISSION.md`](docs/SUBMISSION.md) cho các mục nộp bài còn thiếu.

## Chức năng

- Camera preview, flash, chạm lấy nét/đo sáng, khung hóa đơn; chọn ảnh từ thư viện.
- Cắt và xoay ảnh trước khi nhận diện bằng ML Kit Latin trên thiết bị.
- Regex gợi ý cửa hàng, tổng tiền VND và ngày; lọc subtotal, cash/change, tax, phone/invoice.
- Review cho sửa thông tin, xem văn bản OCR/vùng chữ và yêu cầu xác nhận trước khi lưu.
- SQLite CRUD, số tiền nguyên VND; ảnh hóa đơn và thumbnail lưu trong bộ nhớ ứng dụng.
- Riverpod AsyncNotifier; Material 3 sáng/tối và lưu lựa chọn theme.
- Donut danh mục và biểu đồ cột 7 ngày bằng CustomPainter, hoạt ảnh và chạm chọn.
- Lịch sử, tìm kiếm, lọc danh mục, sửa/xóa và kéo để nạp lại.

## Cài APK có sẵn

Chép `releases/app-release.apk` vào Android **7.0 / API 24 trở lên** và cài đặt.
Nếu đã cài bản debug, cần gỡ bản đó vì chữ ký khác nhau; dữ liệu trong app sẽ bị xóa.
APK hỗ trợ `arm64-v8a`, `armeabi-v7a` và `x86_64`.
Sau khi cài, thử camera/crop/OCR, kiểm tra trước khi lưu, mở lại app, sửa/xóa,
biểu đồ và quét khi bật chế độ máy bay. iPhone không cài được APK; dự án này bàn giao Android.

## Môi trường và chạy từ mã nguồn

Khuyến nghị Flutter **3.47.7**, Dart **3.13.5**. Dependencies hiện tại cần Dart >=3.12 và Flutter >=3.44.
Android Gradle Plugin 9.1.0, Gradle 9.3.1, Kotlin 2.4.0; compile/target SDK 36, min SDK 24,
NDK 28.2.13676358. Máy đã build dùng Android Studio JBR 25. Cài Android SDK và chấp nhận license.

```powershell
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

Build debug với script:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Mode debug -FlutterSdk "C:\path\to\flutter"
```

Nếu Flutter đã ở PATH, bỏ `-FlutterSdk`. Dùng `-AndroidSdk` khi SDK ở vị trí khác.
Script đặt cache trong `.local-cache/`. `-VerboseBuild` hiện log chi tiết;
`-StorageMirror` dùng CFUG mirror cho Flutter engine khi nguồn Google tải chậm;
`-SkipChecks` bỏ format/analyze/test nếu đã đạt và mã nguồn chưa đổi.
Script vẫn để Flutter tạo lại plugin registrant theo debug/release; không dùng `--no-pub`.
Xem `tools/check-build.ps1` để đọc tiến độ download thực trên Windows và kiểm tra APK.

## Build release và khóa ký

APK bàn giao đã được ký. **Khóa ký và mật khẩu không nằm trong thư mục/ZIP này.**
Trên máy đã build, khóa riêng đang ở thư mục `receipt_lens-signing` cạnh dự án gốc;
`android/key.properties` của dự án gốc chứa cấu hình riêng. Sao lưu hai mục đó ở nơi riêng tư.

Để build lại bằng cùng chữ ký, tự tạo file `android/key.properties` trong bản mã nguồn này:

```properties
storeFile=C:/private/receipt-lens-upload.p12
storePassword=YOUR_PRIVATE_PASSWORD
keyPassword=YOUR_PRIVATE_PASSWORD
keyAlias=upload
```

Trỏ `storeFile` đến khóa riêng đã sao lưu, rồi chạy:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Mode release -FlutterSdk "C:\path\to\flutter"
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.
Không sửa Java generated để bỏ plugin test. Các quy tắc R8 riêng cho bộ OCR không dùng
nằm trong `android/app/proguard-rules.pro`; app hiện chỉ chọn Latin.
Xem [`docs/RELEASE.md`](docs/RELEASE.md) để kiểm tra checksum/chữ ký và giới hạn kiểm thử.

## Kiến trúc

```text
lib/core/       Theme và định dạng tiền/ngày
lib/models/     Expense và ExpenseCategory
lib/services/   OCR, regex parser, ảnh/thumbnail, SQLite
lib/state/      Riverpod và theme preferences
lib/screens/    Home, capture, review
lib/widgets/    Charts và OCR bounding boxes
test/           8 parser + 2 SQLite FFI + 2 review widget tests
integration_test/  Kiểm thử trên thiết bị
android/        Android scaffold, Gradle, manifest, R8 rules
tools/          Build và kiểm tra tiến độ
docs/           Báo cáo, regex table, demo script, verification
releases/       APK release và SHA256SUMS
```

Review là ranh giới commit: thiếu ngày, tiền không hợp lệ hoặc chưa xác nhận thì không lưu.
DB lỗi sẽ dọn ảnh mới; lỗi reload sau commit không xóa ảnh đã lưu.
Camera được release khi inactive, thumbnail resize chạy ở isolate.

## Kiểm thử và tài liệu

`flutter test` chạy parser, SQLite FFI và review validation. SQLite FFI không thay thế kiểm thử SQLite trên điện thoại.
Integration test tạo dữ liệu thử trong app:

```powershell
flutter test integration_test/app_test.dart -d <device-id>
```

Chưa có kết quả native integration test và phép đo OCR dưới 100 ms.
Merchant/date/total là heuristic; luôn đối chiếu ảnh. Chỉ hỗ trợ VND nguyên, tối đa 1.000.000.000 đ;
ngày DD/MM/YYYY, DD-MM-YYYY hoặc DD.MM.YYYY từ năm 2000 đến 2100.
Ảnh mờ/nghiêng cần sửa tay; chưa có perspective correction, đồng bộ cloud hoặc cấu hình iOS.

- [`docs/VERIFICATION.md`](docs/VERIFICATION.md): bằng chứng và phạm vi kiểm thử.
- [`docs/REPORT.md`](docs/REPORT.md): nguồn Markdown của báo cáo.
- [`docs/REGEX_TABLE.md`](docs/REGEX_TABLE.md): các regex và ví dụ.
- [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md): kịch bản video 2-3 phút.
- [`docs/BUILD-DIAGNOSIS.md`](docs/BUILD-DIAGNOSIS.md): lịch sử lỗi build và cách xử lý.

## GitHub / CI

Thư mục này có thể dùng làm repository Flutter. Keystore, mật khẩu, cache, file generated và APK
đã được gitignore. Đưa APK lên GitHub Releases hoặc Drive, rồi điền URL trong báo cáo.
Workflow `.github/workflows/android.yml` chạy analyze/test và build; thiếu signing secrets sẽ build debug.
Muốn CI build release, tự cấu hình `KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.
Chưa xuất bản repository hoặc video trong lần bàn giao này.
