# Demo 2-3 phút trên điện thoại Android

Đây là kịch bản quay, không phải video đã quay. Cần hóa đơn thật, điện thoại đã bật USB debugging, ứng dụng đã cài và đường dẫn GitHub.

| Thời gian | Thao tác | Nội dung thuyết minh |
|---|---|---|
| 0:00-0:20 | Mở Receipt Lens, đổi sáng/tối | App Flutter quản lý chi tiêu; dữ liệu lưu tại thiết bị. |
| 0:20-0:50 | Thêm chi tiêu > Quét hóa đơn; bật/tắt flash, chạm lấy nét, chụp | Camera và khung giúp căn chỉnh. Cắt vùng chứa hóa đơn trong trình crop. |
| 0:50-1:25 | Xem vùng chữ OCR, mở văn bản gốc; đối chiếu tổng tiền/ngày/tên | ML Kit nhận diện chữ trên thiết bị. Regex chỉ đề xuất; phải sửa các sai sót trước khi lưu. |
| 1:25-1:45 | Chọn danh mục, xác nhận đã kiểm tra, lưu | Chỉ lúc xác nhận mới commit vào SQLite. |
| 1:45-2:10 | Chạm donut/cột; mở danh sách, tìm giao dịch, sửa số tiền | Riverpod nạp lại dữ liệu và biểu đồ CustomPainter cập nhật có hoạt ảnh. |
| 2:10-2:40 | Đóng/mở lại app; bật chế độ máy bay, quét lần nữa | Kiểm tra persistence và OCR offline. Lần chạy đầu có thể chậm hơn do khởi tạo. |
| 2:40-3:00 | Hiển thị repository, README, APK và PDF | Ghi rõ kết quả kiểm thử thực tế và các giới hạn. |

## Tiêu chí kiểm tra trên thiết bị

- Từ chối quyền camera: hiển thị lỗi và vẫn chọn được ảnh.
- Hủy chụp/crop/review: không tạo giao dịch.
- Tổng 150.000 đ, tiền khách đưa 200.000 đ: chọn tổng 150.000 đ.
- OCR thiếu ngày hoặc số tiền: phải nhập đúng trước khi lưu.
- Chưa tick xác nhận: không lưu.
- Sửa/xóa: danh sách và biểu đồ phản ánh thay đổi.
- Đóng/mở app: dữ liệu, ảnh thu nhỏ và chủ đề còn tồn tại.
- Chế độ máy bay: OCR, CRUD và charts hoạt động.
- Kiểm tra ảnh thật sáng rõ và ảnh mờ/nghiêng; không suy diễn cam kết OCR dưới 100 ms.
- Chụp 3-4 ảnh màn hình thật (dashboard sáng/tối, review OCR, lịch sử) để thay ảnh bằng chứng trong báo cáo.
