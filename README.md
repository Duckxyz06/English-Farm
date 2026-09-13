# English Farm 🌱

Game nông trại học tiếng Anh với Momo, chú mèo cam trắng đeo khăn xanh. Bản Visual Demo mở rộng hình ảnh từ 5 bảng tham chiếu trong [image/](image/) và đưa chúng vào gameplay Godot.

## Chơi trên Windows

1. Mở [GitHub Actions — Godot Visual Demo](https://github.com/Duckxyz06/English-Farm/actions/workflows/godot-alpha.yml), chọn lượt chạy thành công của nhánh `codex/visual-farm-demo`.
2. Tải artifact **EnglishFarm-Windows-Visual-Demo** ở cuối trang lượt chạy. GitHub yêu cầu đăng nhập để tải artifact.
3. Giải nén toàn bộ gói, mở **EnglishFarm.exe** và giữ **EnglishFarm.pck** cùng thư mục.

Hướng dẫn đầy đủ có trong [PLAY_DEMO_VI.txt](docs/PLAY_DEMO_VI.txt) và tệp HUONG_DAN.txt đi kèm gói Windows.

## Có trong bản demo

- Nông trại mùa xuân 3072×2048 với nhà Momo ở phía tây nam, trường, kho, ruộng, hồ và lối đi.
- Bộ hình Momo 16 khung cho bốn hướng; Lily, Tom, Mia mỗi người hai tư thế; bộ 16 hình cây và vật phẩm.
- Đi bằng bàn phím hoặc bấm chuột, tìm đường tránh công trình/hồ, camera theo nhân vật và bản đồ nhỏ có thể bấm.
- Lily dạy 10 từ: mỗi đáp án đúng mới nhận 2 XP; hoàn thành bài học nhận 50 xu một lần.
- Tám luống: gieo → tưới → đợi 12 giây → thu hoạch. Tom nhận 3 cà rốt và thưởng 30 xu, 20 XP một lần.
- Kho 60 chỗ, nâng lên 100 với 500 xu; mua hạt giống, bán cà rốt; đổi 10 xu lấy 1 ngọc và mua mũ với 5 ngọc.
- Tự lưu tiến độ, có bản sao lưu; nhạc nền và bốn hiệu ứng âm thanh mới, có nút tắt tiếng.

## Điều khiển

| Thao tác | Điều khiển |
| --- | --- |
| Di chuyển, hủy hành trình bằng chuột | W A S D |
| Chọn điểm đến / NPC / luống cây | Chuột trái, cả trên bản đồ nhỏ |
| Tương tác, tiếp tục sau đáp án đúng | E |
| Chọn đáp án hoặc thao tác cửa hàng | 1–5 |
| Mở kho / đóng cửa sổ | I / Esc |
| Bật tắt âm thanh / toàn màn hình | M / F11 |

Momo bắt đầu trước nhà. Hãy gặp Lily trước trường mái xanh, vào ruộng từ cổng phía dưới, rồi mang cà rốt đến Tom ở phía dưới bên phải ruộng. Mia đứng trước kho mái đỏ ở phía đông bắc.

## Phát triển và kiểm thử

Mở `project.godot` bằng **Godot 4.3 stable** và nhấn F5. Scene chính là `game/scenes/Main.tscn`; các module đang dùng nằm trong `game/scripts/`.

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_game.gd
```

Workflow kiểm tra import và gameplay, chụp màn hình thật bằng Godot với màn hình ảo, rồi mới xuất Windows. Artifact **EnglishFarm-Verification** chứa log và ảnh chụp. Kiểm thử bao gồm đường đi đến cả ba NPC/tám luống, khóa di chuyển khi hội thoại, chống nhận thưởng lặp, mua bán khi thiếu tiền/đầy kho và khôi phục bản lưu hỏng.

Chi tiết nguồn ảnh, atlas và âm thanh: [VISUAL_DEMO_ASSETS.md](docs/VISUAL_DEMO_ASSETS.md). Nhạc có thể tái tạo bằng `python tools/compose_audio.py` (cần NumPy).

## Phạm vi tiếp theo

Demo hiện có một khu nông trại, một loại cây và một bài học 10 từ. Chuyển mùa, vùng rừng/núi/biển/đảo, nội thất, nhiều cây trồng và ghi âm/chấm phát âm vẫn là các mốc tiếp theo. Ảnh mới theo phong cách và nhận diện của ảnh tham chiếu; không phải bản sao trùng từng pixel.

Các báo cáo Prototype/Alpha cũ trong docs là lịch sử dự án; README này mô tả bản Visual Demo.
