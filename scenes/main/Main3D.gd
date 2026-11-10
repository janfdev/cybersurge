extends Node3D
class_name MainGame3D

enum GameState { COMBAT, SHOP, GAME_OVER }

const Enemy3DScript = preload("res://scenes/entities/enemies/Enemy3D.gd")

var current_state: GameState = GameState.COMBAT
var wave_time_left: float = 45.0
var _spawn_cooldown: float = 1.6
var enemy_scene = preload("res://scenes/entities/enemies/Enemy3D.tscn")

@onready var player: CharacterBody3D = $PlayerFPS
@onready var hud: CanvasLayer = $HUD3D
@onready var shop_modal: CanvasLayer = $ShopModal
@onready var game_over_modal: CanvasLayer = $GameOverModal
@onready var enemies_container: Node3D = $EnemiesContainer

func _ready() -> void:
	if not player:
		return
		
	# Connect signals from PlayerFPS
	player.health_changed.connect(_on_player_health_changed)
	player.player_died.connect(_on_player_died)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.hit_registered.connect(_on_hit_registered)
	
	if shop_modal:
		if shop_modal.has_signal("shop_closed"):
			shop_modal.connect("shop_closed", _on_shop_closed)
		if shop_modal.has_signal("upgrade_purchased"):
			shop_modal.connect("upgrade_purchased", _on_upgrade_purchased)
		
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.reset_run()
		gd.chips_updated.connect(_on_chips_updated)
		
	start_wave(1)

func _physics_process(delta: float) -> void:
	if current_state != GameState.COMBAT:
		return
		
	var gd = get_node_or_null("/root/GameData")
	var current_wave: int = gd.current_wave if gd else 1
	
	wave_time_left -= delta
	if hud and hud.has_method("update_timer"):
		hud.update_timer(wave_time_left)
		
	if wave_time_left <= 0.0:
		end_wave()
		return
			
	# Enemy Spawning logic in 3D Arena
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_spawn_cooldown = max(0.8, 1.8 - (current_wave * 0.2))
		_spawn_enemy()

func start_wave(wave: int) -> void:
	current_state = GameState.COMBAT
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.set_wave(wave)
		
	match wave:
		1: wave_time_left = 45.0
		2: wave_time_left = 50.0
		3: wave_time_left = 60.0
		4: wave_time_left = 60.0
		5: wave_time_left = 90.0
			
	if hud:
		if hud.has_method("update_wave"):
			hud.update_wave(wave)
		if hud.has_method("update_timer"):
			hud.update_timer(wave_time_left)

	# Spawn immediate initial wave of enemies right in front of player
	for i in range(3):
		_spawn_enemy(true)

func end_wave() -> void:
	current_state = GameState.SHOP
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_clear_enemies()
	if shop_modal and shop_modal.has_method("open_shop"):
		shop_modal.open_shop()

func _spawn_enemy(immediate_in_sight: bool = false) -> void:
	if not enemy_scene or not enemies_container:
		return
		
	var spawn_pos: Vector3
	if immediate_in_sight and player:
		# Spawn ahead of the player in line of sight (12m - 18m away)
		var forward = -player.global_transform.basis.z
		var side = player.global_transform.basis.x
		spawn_pos = player.global_position + forward * randf_range(12.0, 18.0) + side * randf_range(-6.0, 6.0)
		spawn_pos.y = 0.95
	else:
		# Spawn around player within arena perimeter
		var angle := randf_range(0, TAU)
		var spawn_dist := randf_range(14.0, 22.0)
		spawn_pos = Vector3(cos(angle) * spawn_dist, 0.95, sin(angle) * spawn_dist)
	
	var en = enemy_scene.instantiate()
	en.position = spawn_pos
	enemies_container.add_child(en)

func _clear_enemies() -> void:
	if enemies_container:
		for child in enemies_container.get_children():
			child.queue_free()

func _on_player_health_changed(current: int, max_hp: int) -> void:
	if hud and hud.has_method("update_health"):
		hud.update_health(current, max_hp)

func _on_player_ammo_changed(current: int, max_mag: int, reserve: int) -> void:
	if hud and hud.has_method("update_ammo"):
		hud.update_ammo(current, max_mag, reserve)

func _on_hit_registered(is_headshot: bool) -> void:
	if hud and hud.has_method("flash_hit"):
		hud.flash_hit(is_headshot)

func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if game_over_modal and game_over_modal.has_method("show_game_over"):
		var gd = get_node_or_null("/root/GameData")
		var kills = gd.total_kills if gd else 0
		var chips = gd.nano_chips if gd else 0
		game_over_modal.show_game_over(kills, chips)

func _on_chips_updated(new_amount: int) -> void:
	if hud and hud.has_method("update_chips"):
		hud.update_chips(new_amount)

func _on_shop_closed() -> void:
	var gd = get_node_or_null("/root/GameData")
	var next_wave: int = (gd.current_wave + 1) if gd else 2
	start_wave(next_wave)

func _on_upgrade_purchased(_upgrade_id: String) -> void:
	# Refill ammo on upgrade / purchase
	if player:
		player.reserve_ammo += 36
		player.ammo_changed.emit(player.current_ammo, player.mag_capacity, player.reserve_ammo)
