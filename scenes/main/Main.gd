extends Node2D
class_name MainGame

enum GameState { COMBAT, SHOP, GAME_OVER }

var current_state: GameState = GameState.COMBAT
var wave_time_left: float = 45.0
var _spawn_cooldown: float = 1.0
var _enforcer_cooldown: float = 3.0
var _boss_instance: Node2D = null

@onready var player: Node2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var shop_modal: CanvasLayer = $ShopModal
@onready var game_over_modal: CanvasLayer = $GameOverModal
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var weapons_container: Node2D = $Player/WeaponsContainer

func _ready() -> void:
	if not player:
		return
		
	# Connect signals
	if player.has_signal("health_changed"):
		player.connect("health_changed", _on_player_health_changed)
	if player.has_signal("player_died"):
		player.connect("player_died", _on_player_died)
	
	if shop_modal:
		if shop_modal.has_signal("shop_closed"):
			shop_modal.connect("shop_closed", _on_shop_closed)
		if shop_modal.has_signal("upgrade_purchased"):
			shop_modal.connect("upgrade_purchased", _on_upgrade_purchased)
		
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.reset_run()
		gd.chips_updated.connect(_on_chips_updated)
		
	_sync_weapons()
	start_wave(1)
	queue_redraw()

func _draw() -> void:
	# Draw procedural arena perimeter and subtle neon grid
	var border_color := Color(0.0, 0.94, 1.0, 0.4)
	var arena_rect := Rect2(-1500, -1500, 3000, 3000)
	draw_rect(arena_rect, border_color, false, 4.0)

func _physics_process(delta: float) -> void:
	if current_state != GameState.COMBAT:
		return
		
	# Camera follows player smoothly
	if camera and player:
		camera.global_position = camera.global_position.lerp(player.global_position, 10.0 * delta)
		
	var gd = get_node_or_null("/root/GameData")
	var current_wave: int = gd.current_wave if gd else 1
	
	# Wave 5: Timer stops, victory depends on defeating the Boss
	if current_wave < 5:
		wave_time_left -= delta
		if hud and hud.has_method("update_timer"):
			hud.update_timer(wave_time_left)
		if wave_time_left <= 0.0:
			end_wave()
			return
			
	# Enemy Spawning logic
	_handle_spawning(delta, current_wave)

func start_wave(wave: int) -> void:
	current_state = GameState.COMBAT
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.set_wave(wave)
		
	match wave:
		1: wave_time_left = 45.0
		2: wave_time_left = 50.0
		3: wave_time_left = 60.0
		4: wave_time_left = 60.0
		5:
			wave_time_left = 0.0
			_spawn_boss()
			
	if hud:
		if hud.has_method("update_wave"):
			hud.update_wave(wave)
		if hud.has_method("update_timer"):
			hud.update_timer(wave_time_left)

func end_wave() -> void:
	current_state = GameState.SHOP
	_clear_enemies()
	if shop_modal and shop_modal.has_method("open_shop"):
		shop_modal.open_shop()

func _on_shop_closed() -> void:
	var gd = get_node_or_null("/root/GameData")
	var next_wave: int = (gd.current_wave + 1) if gd else 2
	_sync_weapons()
	start_wave(next_wave)

func _on_upgrade_purchased(_upgrade_id: String) -> void:
	_sync_weapons()

func _sync_weapons() -> void:
	if not weapons_container:
		return
	var gd = get_node_or_null("/root/GameData")
	var active: Array = gd.active_weapons if gd else ["blaster"]
	
	# Pulse Blaster
	if active.has("blaster") and not weapons_container.has_node("BlasterWeapon"):
		var b_scene = load("res://scenes/weapons/BlasterWeapon.tscn")
		if b_scene:
			weapons_container.add_child(b_scene.instantiate())
			
	# Orbiting Blade
	if active.has("orbit") and not weapons_container.has_node("OrbitBladeWeapon"):
		var o_scene = load("res://scenes/weapons/OrbitBladeWeapon.tscn")
		if o_scene:
			weapons_container.add_child(o_scene.instantiate())

func _handle_spawning(delta: float, wave: int) -> void:
	_spawn_cooldown -= delta
	var spawn_rate: float = 1.2
	match wave:
		1: spawn_rate = 1.2
		2: spawn_rate = 0.8
		3: spawn_rate = 0.6
		4: spawn_rate = 0.4
		5: spawn_rate = 3.0
		
	if _spawn_cooldown <= 0.0:
		_spawn_cooldown = spawn_rate
		_spawn_drone()
		
	if wave >= 3 and wave < 5:
		_enforcer_cooldown -= delta
		var enf_rate: float = 3.0 if wave == 3 else 2.0
		if _enforcer_cooldown <= 0.0:
			_enforcer_cooldown = enf_rate
			_spawn_enforcer()

func _get_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO
	# Spawn on a circle perimeter around player (distance 720 px)
	var angle := randf() * TAU
	return player.global_position + Vector2(cos(angle), sin(angle)) * 720.0

func _spawn_drone() -> void:
	var drone_scene = load("res://scenes/entities/enemies/DroneEnemy.tscn")
	if drone_scene and enemies_container:
		var drone = drone_scene.instantiate()
		drone.global_position = _get_spawn_position()
		enemies_container.add_child(drone)

func _spawn_enforcer() -> void:
	var enf_scene = load("res://scenes/entities/enemies/HeavyEnforcer.tscn")
	if enf_scene and enemies_container:
		var enf = enf_scene.instantiate()
		enf.global_position = _get_spawn_position()
		enemies_container.add_child(enf)

func _spawn_boss() -> void:
	var boss_scene = load("res://scenes/entities/enemies/BossMegaMech.tscn")
	if boss_scene and enemies_container:
		_boss_instance = boss_scene.instantiate()
		_boss_instance.global_position = _get_spawn_position()
		if _boss_instance.has_signal("enemy_died"):
			_boss_instance.connect("enemy_died", _on_boss_defeated)
		enemies_container.add_child(_boss_instance)

func _on_boss_defeated(_pos: Vector2, _chips: int) -> void:
	current_state = GameState.GAME_OVER
	_clear_enemies()
	var gd = get_node_or_null("/root/GameData")
	var kills: int = gd.total_kills if gd else 0
	var chips: int = gd.nano_chips if gd else 0
	if game_over_modal and game_over_modal.has_method("show_result"):
		game_over_modal.show_result(true, kills, chips)

func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	var gd = get_node_or_null("/root/GameData")
	var kills: int = gd.total_kills if gd else 0
	var chips: int = gd.nano_chips if gd else 0
	if game_over_modal and game_over_modal.has_method("show_result"):
		game_over_modal.show_result(false, kills, chips)

func _clear_enemies() -> void:
	if enemies_container:
		for child in enemies_container.get_children():
			child.queue_free()

func _on_player_health_changed(current: int, max_hp: int) -> void:
	if hud and hud.has_method("update_health"):
		hud.update_health(current, max_hp)

func _on_chips_updated(amount: int) -> void:
	if hud and hud.has_method("update_chips"):
		hud.update_chips(amount)
