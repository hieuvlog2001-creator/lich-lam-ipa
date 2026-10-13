# Lịch Làm iOS — GitHub Actions

Ứng dụng iOS dạng WebView mở `https://misamod.site`, có nút tải lại, quay lại và mở lại trang chủ. Đăng nhập quản trị vẫn thực hiện trên website tại `/admin`.

## Build trên GitHub
1. Tạo repository GitHub mới.
2. Giải nén gói này rồi upload toàn bộ nội dung lên repository (giữ nguyên `.github/workflows/build-ios.yml`).
3. Vào **Actions** và bật workflow nếu GitHub yêu cầu.
4. Mở tab **Actions** → chọn **Build Lịch Làm iOS** → **Run workflow**.
5. Khi chạy xong, tải artifact `LichLam-iOS-tipa` ở cuối trang run.

Workflow build bằng runner macOS của GitHub. Gói đầu ra `.tipa` được tạo từ ứng dụng **chưa ký**; để cài cần phương thức sideload tương thích và có thể cần ký ứng dụng theo công cụ/thiết bị của bạn.

## Đổi địa chỉ website
Sửa `Config.swift`, thay `https://misamod.site`.

## Lưu ý
- Đây là ứng dụng WebView, không thay thế backend Cloudflare Worker.
- Dữ liệu vẫn lấy từ website/Google Sheets hiện có; app không tạo database mới.
- Build trên GitHub không cần máy Mac cá nhân, nhưng repository phải cho phép GitHub Actions chạy.


## Giao diện iOS gọn 3 cột
Trong app iOS, WebView tự tinh chỉnh bảng lịch thành 3 cột: STT, Họ và tên, Ca làm. Cột vị trí/trạng thái được ẩn trong app, tên bộ phận vẫn ở dưới tên nhân viên, và mã ca có nhãn phụ như M6 / Ca sáng, A2 / Ca chiều, N10 / Ca đêm. Đây là thay đổi chỉ trong ứng dụng iOS; website và dữ liệu Google Sheets không bị thay đổi.
