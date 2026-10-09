# Release 1.0.0+1 - 09/10/2026

- Sinh viên: Trần Thanh Quý - 23IT228.
- Package: `vn.vku.receiptlens`.
- APK: `../releases/app-release.apk` (92,399,631 byte).
- SHA-256: `7654c2f41e06a590477ad93ca15a937cf7490d5820220debf5eb8495f3657ea5`.
- Signing certificate SHA-256: `2a47180eb61f915a227fbc37d6cceaecb6c03e06f3599b197c420a3aea50d84d`.
- Certificate subject: `CN=Receipt Lens, OU=Mobile Project, O=Receipt Lens, C=VN`.
- `apksigner verify --verbose --print-certs`: đạt, APK Signature Scheme v2.

Đây là bản release có khóa riêng, không dùng Android Debug certificate. APK chưa được thay đổi sau khi ký.
Kiểm tra checksum trong PowerShell: `Get-FileHash releases/app-release.apk -Algorithm SHA256`.
So sánh với `releases/SHA256SUMS.txt`. Khóa ký/mật khẩu được giữ riêng, không có trong gói này.

Analyze không có issue; 12 tests đạt; người dùng báo test debug OK. Cần test lại release trên Android:
camera/crop, OCR offline, review trước save, CRUD/persistence sau restart, ảnh cache và charts.
Debug và release có chữ ký khác nhau; gỡ debug trước khi cài release sẽ xóa dữ liệu thử.
