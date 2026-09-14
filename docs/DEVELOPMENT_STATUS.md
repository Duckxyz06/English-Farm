# English Farm — Visual Demo

Mốc cập nhật: 13/09/2026. Mã game được xác minh: `dae5007600cb85e2a77ff0ad83c3a8cb676726d2`.

[Windows tải về](https://github.com/Duckxyz06/English-Farm/actions/runs/34790434690/artifacts/10328225832) · [CI thành công](https://github.com/Duckxyz06/English-Farm/actions/runs/34790434690) · [PR #1](https://github.com/Duckxyz06/English-Farm/pull/1)

## Đã tích hợp

| Phần | Nội dung đang chạy |
| --- | --- |
| Hình ảnh | Nông trại mùa xuân, Momo 16 khung/bốn hướng, ba NPC người, 16 hình vật phẩm/cây |
| Di chuyển | WASD, bấm chuột, bản đồ nhỏ, đường đi tránh hồ/công trình, camera theo Momo |
| Học tập | 10 từ, 2 XP mỗi từ mới, thưởng 50 xu một lần, sổ ôn tập |
| Trồng trọt | 8 luống, gieo–tưới–lớn sau 12 giây–thu hoạch |
| Nhiệm vụ | Giao Tom 3 cà rốt, nhận 30 xu và 20 XP một lần |
| Cửa hàng | Mua giống, bán cà rốt, kho 60→100, 10 xu→1 ngọc, mũ 5 ngọc |
| Tiến độ | Tự lưu, kiểm tra dữ liệu tải vào, khôi phục bản dự phòng |
| Âm thanh | Một giai điệu mới, bốn hiệu ứng, nút bật/tắt |

## Xác minh

Godot 4.3 stable trên GitHub Actions đã import, chạy kiểm thử gameplay và âm thanh, chụp 8 màn hình qua OpenGL với màn hình ảo rồi xuất Windows thành công. Đã xem trực tiếp các ảnh: nhà Momo, ruộng, bài học, giao dịch cửa hàng, Mia, mũ, kho và sổ từ vựng. Gói ZIP 38.620.896 byte đã đối chiếu SHA-256 với artifact và kiểm tra CRC; chứa executable Windows x86-64, PCK và hướng dẫn.

Đây là kiểm thử runtime Godot trên Linux và kiểm tra gói xuất Windows; chưa có phiên chơi thủ công trên máy Windows trong đợt này.

## Tiếp tục phát triển

Scene chính: `game/scenes/Main.tscn`. Mã đang dùng nằm trong `game/scripts/`; dữ liệu bài học ở `data/lessons.json`. Các thư mục scripts/ui cũ giữ lại từ prototype, không phải điểm vào hiện tại.

Bản đồ là ảnh nền cố định phóng 2 lần; khi đổi vị trí công trình phải cập nhật vùng đi trong `farm_navigation.gd`. Các kết nối tìm đường được kiểm tra với khoảng trống lớn hơn bàn chân nhân vật để tránh mắc ở mép đường. PNG atlas giữ nguyên, shader loại nền magenta; xem [nguồn tài nguyên](VISUAL_DEMO_ASSETS.md).

Các mốc chưa làm: thêm cây và bài học; nội thất và các khu vực nối với nhau; mùa/thời gian; ghi âm và chấm phát âm. Hiện chỉ có một khu nông trại, một loại cây và một bài học 10 từ.
