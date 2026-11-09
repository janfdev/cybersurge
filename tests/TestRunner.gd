extends SceneTree

func _init() -> void:
	print("[TestRunner] Initializing CyberSurge Test Suite...")
	var success := run_all_tests()
	if success:
		print("[TestRunner] ALL TESTS PASSED.")
		quit(0)
	else:
		push_error("[TestRunner] TESTS FAILED.")
		quit(1)

func run_all_tests() -> bool:
	if not test_project_bootstrap():
		return false
	if not test_game_data_economy():
		return false
	if not test_nano_chip_magnet():
		return false
	if not test_player_entity():
		return false
	if not test_weapons():
		return false
	return true

func test_project_bootstrap() -> bool:
	print("[TEST] test_project_bootstrap...")
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	
	if width != 1280 or height != 720 or stretch_mode != "canvas_items":
		print("  FAIL: Project settings mismatch.")
		return false
		
	print("  PASS: Project viewport configured to 1280x720 (canvas_items).")
	return true

func test_game_data_economy() -> bool:
	print("[TEST] test_game_data_economy...")
	var game_data_script = load("res://scripts/GameData.gd")
	var gd = game_data_script.new()
	gd.reset_run()
	gd.add_chips(50)
	if not gd.spend_chips(30) or gd.nano_chips != 20:
		return false
	if gd.spend_chips(25):
		return false
	if not gd.spend_chips(20) or gd.nano_chips != 0:
		return false
	print("  PASS: GameData economy verified.")
	return true

func test_nano_chip_magnet() -> bool:
	print("[TEST] test_nano_chip_magnet...")
	var chip_scene = load("res://scenes/entities/drops/NanoChip.tscn")
	var chip = chip_scene.instantiate()
	root.add_child(chip)
	chip.global_position = Vector2(100, 100)
	
	var mock_target = Node2D.new()
	root.add_child(mock_target)
	mock_target.global_position = Vector2(200, 100)
	
	chip.set_magnet_target(mock_target)
	var initial_dist = chip.global_position.distance_to(mock_target.global_position)
	chip._physics_process(0.1)
	var new_dist = chip.global_position.distance_to(mock_target.global_position)
	
	chip.queue_free()
	mock_target.queue_free()
	if new_dist >= initial_dist:
		return false
	print("  PASS: NanoChip magnet attraction verified.")
	return true

func test_player_entity() -> bool:
	print("[TEST] test_player_entity...")
	var player_scene = load("res://scenes/entities/player/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector2(500, 500)
	
	if player.get_closest_enemy() != null:
		player.queue_free()
		return false
		
	var hp_before = player.current_health
	player.take_damage(25)
	if player.current_health != hp_before - 25:
		player.queue_free()
		return false
		
	player.take_damage(25)
	if player.current_health != hp_before - 25:
		player.queue_free()
		return false
		
	print("  PASS: Player entity targeting and health mechanics verified.")
	player.queue_free()
	return true

func test_weapons() -> bool:
	print("[TEST] test_weapons...")
	var blaster_scene = load("res://scenes/weapons/BlasterWeapon.tscn")
	if not blaster_scene:
		print("  FAIL: BlasterWeapon.tscn not found.")
		return false
	var orbit_scene = load("res://scenes/weapons/OrbitBladeWeapon.tscn")
	if not orbit_scene:
		print("  FAIL: OrbitBladeWeapon.tscn not found.")
		return false
	var tesla_scene = load("res://scenes/weapons/TeslaArcWeapon.tscn")
	if not tesla_scene:
		print("  FAIL: TeslaArcWeapon.tscn not found.")
		return false
		
	var blaster = blaster_scene.instantiate()
	root.add_child(blaster)
	if blaster.base_damage <= 0 or blaster.cooldown <= 0.0:
		blaster.queue_free()
		return false
	blaster.queue_free()
	
	var orbit = orbit_scene.instantiate()
	root.add_child(orbit)
	if orbit.orbit_radius <= 0.0:
		orbit.queue_free()
		return false
	orbit.queue_free()
	
	var tesla = tesla_scene.instantiate()
	root.add_child(tesla)
	if tesla.max_chains < 2:
		tesla.queue_free()
		return false
	tesla.queue_free()
	
	print("  PASS: All 3 modular procedural weapons verified.")
	return true
