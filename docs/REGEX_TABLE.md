# Heuristic OCR

App chỉ hỗ trợ tiền VND nguyên, không hỗ trợ USD/tiền lẻ thập phân.

| Trường | Quy tắc | Ví dụ |
|---|---|---|
| Tiền | `\d{1,3}(?:[., ]\d{3})+` hoặc chuỗi từ 4 chữ số trong OCR | `150,000 VND`, `150.000 đ`, `150 000` |
| Ưu tiên | `grand total`, `total due`, `amount due`, `thanh toan`, `tong cong`, `tong tien`, `total` sau chuẩn hóa dấu | `TỔNG CỘNG 150.000 đ` |
| Loại bỏ | `subtotal`, `tam tinh`, `cash`, `change`, `tender`, `tax`, `vat`, `discount`, `tien khach`, `khach dua`, `tien thoi`, `giam gia` | Tiền khách đưa không được chọn làm tổng |
| Metadata | Bỏ dòng tel/phone/hotline/MST/invoice/hoa don/tai khoan | Không dùng số điện thoại hoặc số hóa đơn làm tiền |
| Ngày | `\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b`; kiểm tra ngày sau khi khởi tạo DateTime | `09/10/2026` hợp lệ; `31/02/2026` bị bỏ |
| Cửa hàng | Dòng có chữ trong 8 dòng đầu, bỏ metadata, địa chỉ, ngày và lời cảm ơn | `WINMART` |

Điểm ưu tiên là heuristic, không phải xác suất tin cậy. Thiếu nhãn tổng tiền thì cảnh báo và cho người dùng chọn ứng viên/nhập thủ công. Không tự sửa O thành 0 để tránh làm sai tên và mã. OCR tách số thành nhiều dòng, receipt nhiều đơn vị tiền hoặc layout bất thường cần nhập thủ công.
