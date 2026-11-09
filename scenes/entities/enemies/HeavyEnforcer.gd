extends "res://scenes/entities/enemies/EnemyBase.gd"
class_name HeavyEnforcer

func _init() -> void:
	max_health = 140
	move_speed = 100.0
	contact_damage = 25
	chip_drop_value = 5
	knockback_resistance = 0.9

func _draw() -> void:
	# Heavy armored Hexagonal Chassis
	var crimson := Color(0.85, 0.05, 0.25, 1.0)
	var glow := Color(1.0, 0.2, 0.4, 0.4)
	var points := PackedVector2Array([
		Vector2(16, 0),
		Vector2(8, -14),
		Vector2(-12, -14),
		Vector2(-16, 0),
		Vector2(-12, 14),
		Vector2(8, 14)
	])
	draw_colored_polygon(points, crimson)
	draw_polyline(points, glow, 2.5, true)
	# Center red sensor core
	draw_circle(Vector2(4, 0), 4.0, Color.WHITE)
