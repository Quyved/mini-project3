# Kiểm tra build Android — 09/10/2026

## Kết quả cuối

Build debug đã thành công lúc 11:20 ngày 09/10/2026: `BUILD SUCCESSFUL in 10m 33s`. APK có dung lượng 204.146.463 byte. `apksigner verify` đạt với chữ ký APK v2 (Android Debug). Người dùng đã báo test bản debug OK. Bản release đã build thành công lúc 13:03, ký riêng v2 đã xác minh; xem RELEASE.md.

SHA-256 APK debug: `e8743bfe70f7bbfead62513a9e71b889aebe558698c0637e2b7e320926adc755`.

## Kết quả xác minh

- Log PowerShell của người dùng: `flutter analyze` không có lỗi; 12 test đều đạt.
- Cấu hình dự án khớp các giá trị trong SDK Flutter 3.47.7 đang cài: Gradle 9.3.1, Android Gradle Plugin 9.1.0, Kotlin 2.4.0, Java bytecode 17, compile/target SDK 36, min SDK 24, NDK 28.2.13676358.
- Đường dẫn Flutter và Android SDK trong `android/local.properties` đúng. NDK đã cài thành công.
- Java 25 được Gradle 9.3.1 hỗ trợ. Cảnh báo `System::load` không phải thông báo build thất bại.
- Đã đọc mã camera/crop, OCR, parser, màn hình review, SQLite, lưu ảnh, state, lịch sử và CustomPainter. Chưa phát hiện lỗi giải thích việc chờ ở bước build.
- Test trên điện thoại thật, OCR/camera native và bản release ký riêng vẫn cần xác minh; 12 test không thay thế các kiểm tra này.

## Nguyên nhân chờ lâu ghi nhận trong log

Daemon `14744` chạy đến `:app:compileDebugKotlin` rồi tải:

`io.flutter:arm64_v8a_debug:1.0.0-deb287481e3ce9468f3434937ced4240a70539ca`

Máy chủ Google trả về kích thước **180.591.679 byte**. Kiểm tra cùng một đoạn 1 MiB trên máy này:

| Nguồn | Thời gian đo | Tốc độ đo |
| --- | ---: | ---: |
| storage.googleapis.com | 11,84 giây | 88.588 byte/giây |
| storage.flutter-io.cn | 0,44 giây | 2.403.849 byte/giây |

Đây là phép đo tại thời điểm kiểm tra, không bảo đảm tốc độ của lần tải khác. Một bản đầy đủ từ mirror đã tải được trong 15,34 giây và có MD5 `5b07442061735939e5b60227b5a587b3`, trùng metadata do Google trả về. Bản đó chỉ được dùng để kiểm tra, không chèn vào cache Gradle đang chạy.

**Lưu ý Windows:** kích thước và thời gian trong thông tin thư mục có thể chưa cập nhật khi Java đang giữ file mở. Đọc `FileStream.Length` thấy file tăng từ 129,9 MB lên 151,4 MB. Không thể kết luận build đứng chỉ dựa vào `LastWriteTime`.

Lúc 11:17, download đã hoàn tất và Gradle chuyển sang `mergeDebugResources`. Khi đó chưa có APK và chưa thấy thông báo lỗi.

## Công cụ đã bổ sung

Trong thư mục dự án, chạy `powershell -ExecutionPolicy Bypass -File tools\check-build.ps1` để đọc kích thước download thực, đoạn cuối log Gradle và kiểm tra APK. Script chỉ đọc trạng thái; không khởi động hoặc dừng build.

`tools/build.ps1` có các tùy chọn:

- `-SkipChecks`: bỏ format/analyze/test khi những bước đó đã đạt và mã nguồn chưa đổi.
- `-VerboseBuild`: hiện log chi tiết của Flutter/Gradle.
- `-StorageMirror`: dùng `https://storage.flutter-io.cn` cho các thư viện Flutter, chỉ trong tiến trình script. Không đổi nguồn package pub hay cấu hình toàn hệ thống.

Không cần dừng lần build đang có tiến triển để đổi mirror. Chỉ dùng tùy chọn mirror khi cần chạy một lần build mới.

Nguồn đối chiếu: [Flutter mirror](https://docs.flutter.dev/community/china), [Gradle/Java compatibility](https://docs.gradle.org/current/userguide/compatibility.html), [AGP 9.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes).

## Các lỗi release đã xử lý

- Hết dung lượng ổ C: giải phóng file trung gian và build lại.
- GeneratedPluginRegistrant tham chiếu integration_test: bỏ --no-pub để Flutter tạo lại registrant theo release mode.
- R8 báo thiếu các bộ OCR không dùng: thêm 8 quy tắc dontwarn chính xác vào android/app/proguard-rules.pro. App chỉ chọn TextRecognitionScript.latin.
