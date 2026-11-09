extends "res://scenes/entities/enemies/EnemyBase.gd"
class_name DroneEnemy

func _init() -> void:
	max_health = 20
	move_speed = 180.0
	contact_damage = 10
	chip_drop_value = 1
	knockback_resistance = 0.0

func _draw() -> void:
	# Procedural Crimson Triangle Drone
	var magenta := Color(1.0, 0.0, 0.33, 1.0)
	var glow := Color(1.0, 0.0, 0.33, 0.4)
	var points := PackedVector2Array([
		Vector2(10, 0),
		Vector2(-8, -7),
		Vector2(-4, 0),
		Vector2(-8, 7)
	])
	draw_colored_polygon(points, magenta)
	draw_polyline(points, glow, 1.5, true)
