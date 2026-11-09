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
	if not player_scene:
		print("  FAIL: scenes/entities/player/Player.tscn not found.")
		return false
	var player = player_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector2(500, 500)
	
	# Test 0 enemies in range returns null
	if player.get_closest_enemy() != null:
		print("  FAIL: Expected null when no enemies in range.")
		player.queue_free()
		return false
		
	# Test health and damage
	var hp_before = player.current_health
	player.take_damage(25)
	if player.current_health != hp_before - 25:
		print("  FAIL: Player take_damage did not reduce health correctly.")
		player.queue_free()
		return false
		
	# Test invulnerability frames (grace period)
	player.take_damage(25)
	if player.current_health != hp_before - 25:
		print("  FAIL: Invulnerability frames failed to protect against multi-frame hit.")
		player.queue_free()
		return false
		
	print("  PASS: Player entity targeting and health mechanics verified.")
	player.queue_free()
	return true
