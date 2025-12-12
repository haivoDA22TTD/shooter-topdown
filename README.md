# 🧟 Top-Down Zombie Shooter (Godot)

Top-Down Zombie Shooter là một trò chơi bắn súng sinh tồn nhìn từ trên xuống, nơi người chơi phải chống lại những đợt tấn công zombie ngày càng mạnh mẽ. Dự án được phát triển bằng **Godot Engine** với cấu trúc rõ ràng, dễ mở rộng và tối ưu cho cả desktop lẫn mobile.

---

## 🎮 Gameplay
- Điều khiển nhân vật từ góc nhìn top-down.
- Bắn zombie xuất hiện theo từng wave.
- Thu thập đạn, máu và power-up.
- Zombie có nhiều loại: chậm, nhanh, nổ, trùm.
- Hệ thống âm thanh & hiệu ứng va chạm sinh động.

---

## 🛠 Công nghệ sử dụng
- **Godot Engine**
- **GDScript**
- **TileMap** cho bản đồ.
- **Navigation / NavigationAgent** cho AI.
- **Signals** trong Godot để quản lý sự kiện.

---

## 📁 Cấu trúc thư mục

```bash
.
├── assets/
│   ├── sprites/
│   ├── sounds/
│   └── fonts/
├── scenes/
│   ├── player/
│   ├── zombies/
│   ├── ui/
│   └── world.tscn
├── scripts/
│   ├── player.gd
│   ├── zombie.gd
│   ├── spawner.gd
│   └── game_manager.gd
├── icon.png
└── README.md
```
## ▶️ Cách chạy game

Tải Godot ( phiên bản 3.x hoặc 4.x ).

Mở Project Manager.

Chọn Import, trỏ đến thư mục dự án.

Nhấn nút ▶ để chạy game.

## 🧩 Các tính năng nổi bật

AI zombie bám đuổi thông minh.

Hệ thống vũ khí (pistol, shotgun, rifle…).

Wave manager sinh wave khó dần.

Dễ dàng thêm map hoặc chế độ chơi mới.
