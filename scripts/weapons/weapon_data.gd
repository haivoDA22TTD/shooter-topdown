extends Resource
class_name WeaponData

enum WeaponType { PISTOL, RIFLE, SHOTGUN, SMG, SNIPER }

@export var id: String = ""
@export var name_vi: String = ""  # Tên tiếng Việt
@export var weapon_type: WeaponType = WeaponType.PISTOL
@export var damage: int = 15
@export var fire_rate: float = 0.4  # Thời gian giữa các phát bắn
@export var magazine_size: int = 12
@export var reload_time: float = 1.5
@export var spread: float = 0.05  # Độ tản đạn
@export var bullet_speed: float = 600.0
@export var pellets: int = 1  # Số viên đạn mỗi phát (shotgun)

# Màu sắc để vẽ
@export var body_color: Color = Color(0.25, 0.25, 0.25)
@export var handle_color: Color = Color(0.4, 0.3, 0.2)
@export var accent_color: Color = Color(0.5, 0.5, 0.5)

static func create_pistol() -> WeaponData:
	var w = WeaponData.new()
	w.id = "pistol"
	w.name_vi = "Súng Lục"
	w.weapon_type = WeaponType.PISTOL
	w.damage = 15
	w.fire_rate = 0.35
	w.magazine_size = 12
	w.reload_time = 1.2
	w.spread = 0.03
	w.body_color = Color(0.2, 0.2, 0.2)
	w.handle_color = Color(0.35, 0.25, 0.15)
	return w

static func create_rifle() -> WeaponData:
	var w = WeaponData.new()
	w.id = "rifle"
	w.name_vi = "Súng Trường"
	w.weapon_type = WeaponType.RIFLE
	w.damage = 25
	w.fire_rate = 0.12
	w.magazine_size = 30
	w.reload_time = 2.0
	w.spread = 0.06
	w.body_color = Color(0.15, 0.18, 0.12)
	w.handle_color = Color(0.3, 0.22, 0.12)
	w.accent_color = Color(0.4, 0.4, 0.35)
	return w

static func create_shotgun() -> WeaponData:
	var w = WeaponData.new()
	w.id = "shotgun"
	w.name_vi = "Súng Hoa Cải"
	w.weapon_type = WeaponType.SHOTGUN
	w.damage = 12
	w.fire_rate = 0.8
	w.magazine_size = 6
	w.reload_time = 2.5
	w.spread = 0.25
	w.pellets = 6
	w.body_color = Color(0.25, 0.2, 0.15)
	w.handle_color = Color(0.5, 0.35, 0.2)
	return w

static func create_smg() -> WeaponData:
	var w = WeaponData.new()
	w.id = "smg"
	w.name_vi = "Tiểu Liên"
	w.weapon_type = WeaponType.SMG
	w.damage = 10
	w.fire_rate = 0.08
	w.magazine_size = 25
	w.reload_time = 1.5
	w.spread = 0.1
	w.body_color = Color(0.22, 0.22, 0.22)
	w.handle_color = Color(0.3, 0.25, 0.18)
	return w

static func create_sniper() -> WeaponData:
	var w = WeaponData.new()
	w.id = "sniper"
	w.name_vi = "Súng Bắn Tỉa"
	w.weapon_type = WeaponType.SNIPER
	w.damage = 80
	w.fire_rate = 1.5
	w.magazine_size = 5
	w.reload_time = 3.0
	w.spread = 0.01
	w.bullet_speed = 1000.0
	w.body_color = Color(0.18, 0.2, 0.15)
	w.handle_color = Color(0.35, 0.28, 0.18)
	w.accent_color = Color(0.3, 0.3, 0.25)
	return w

static func get_random_weapon() -> WeaponData:
	var weapons = [
		create_pistol(),
		create_rifle(),
		create_shotgun(),
		create_smg(),
		create_sniper()
	]
	return weapons[randi() % weapons.size()]

static func get_random_by_rarity(rarity: int) -> WeaponData:
	# rarity: 0 = common, 1 = rare, 2 = military
	match rarity:
		0:  # Common - pistol hoặc smg
			return [create_pistol(), create_smg()][randi() % 2]
		1:  # Rare - rifle hoặc shotgun
			return [create_rifle(), create_shotgun()][randi() % 2]
		2:  # Military - sniper hoặc rifle
			return [create_sniper(), create_rifle()][randi() % 2]
	return create_pistol()
