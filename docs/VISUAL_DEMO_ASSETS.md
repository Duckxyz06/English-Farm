# Tài nguyên và tích hợp demo

Nguồn tham chiếu: 5 PNG người dùng đưa vào thư mục image/ trên nhánh main.
Mốc nguồn: d2c960af98601deda6101276e9f3517c4b294802.

## Đã tạo

| Tệp | Nội dung | Dùng trong game |
| --- | --- | --- |
| game/assets/momo_walk.png | 16 khung: trước, trái, phải, sau | Momo đi và đứng theo hướng |
| game/assets/npcs.png | 2 tư thế cho mỗi Lily, Tom, Mia | Ba NPC người theo ảnh tổng |
| game/assets/items.png | 16 vật phẩm/cây ở các giai đoạn | Cây cà rốt, kho đồ, mũ |
| game/assets/farm_spring.png | Nông trại mùa xuân 1536×1024 | Thế giới 3072×2048 |
| game/assets/audio/ | Một giai điệu và bốn hiệu ứng | Nhạc nền và phản hồi thao tác |

Ảnh bitmap do công cụ imagegen tạo từ ảnh tham chiếu. Nền magenta của atlas
được loại bằng shader khi hiển thị, giữ nguyên các PNG nguồn. atlas.json chỉ
lưu vùng lấy khung và khoảng đệm để các khung đứng đúng chân.
Nhạc và hiệu ứng được tổng hợp từ giai điệu mới; không có bản ghi giọng nói.
tools/compose_audio.py tái tạo âm thanh (Python + NumPy).

## Yêu cầu hình ảnh

Momo vàng cam, vằn trán, mõm/bụng/chân trắng, khăn xanh và cỏ bốn lá.
Lily là cô giáo người, Tom đội mũ rơm, Mia quàng khăn đỏ.
Nhà Momo ở góc trái dưới; đường đi tách khỏi công trình và hồ.
Tài nguyên mới cần được đánh giá bằng hình chụp gameplay; không cam kết trùng
từng pixel với các bảng tham chiếu.

## Prompt tạo ảnh

Dùng công cụ imagegen tích hợp, tham chiếu trực tiếp các bảng gốc đã xem.

1. Momo: create a 4×4 walking atlas from the approved Momo board; down, left,
right, up rows; four phases each; preserve golden orange tabby identity, white
muzzle/paws, three forehead stripes, green triangular scarf and white clover.
2. Chỉnh nền Momo: keep all sixteen sprites and poses; replace checkerboard only
with uniform pure magenta #FF00FF for color-key rendering.
3. Nông trại: expanded orthographic top-down cozy pixel farm matching the overview
and storage boards; cottage southwest, school northwest, barn northeast, clear
central plaza, empty field south-center, pond southeast, forest borders; no UI,
labels or characters; 3:2 landscape.
4. NPC: 3 columns × 2 rows; human Lily with brown bob and blue book, Tom with straw
hat and blue overalls, Mia with red kerchief and basket; idle and waving poses;
uniform magenta background; match approved identities.
5. Vật phẩm: 4×4 atlas, approved style; seed packet, seedling, growing plant,
mature carrot plant; carrot, apple, watering can, hoe; book, coin, gem, basket;
wood, stone, farmer hat, red backpack; magenta background.

## Xác minh

Workflow Godot Visual Demo phải import không lỗi, vượt kiểm thử gameplay, chụp
4 màn hình thật bằng Godot với màn hình ảo, rồi mới xuất Windows.
