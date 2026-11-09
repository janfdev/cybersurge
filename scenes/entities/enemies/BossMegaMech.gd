extends "res://scenes/entities/enemies/EnemyBase.gd"
class_name BossMegaMech

signal boss_phase_changed(is_phase_two: bool)

var is_phase_two: bool = false
var _attack_timer: float = 3.0

func _init() -> void:
	max_health = 2000
	move_speed = 80.0
	contact_damage = 35
	chip_drop_value = 50
	knockback_resistance = 1.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 2.5 if is_phase_two else 3.5
		_perform_ring_attack()

func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, hit_direction)
	# Check Phase Two transition
	if not is_phase_two and current_health <= (max_health * 0.5):
		is_phase_two = true
		move_speed = 130.0
		boss_phase_changed.emit(true)
		queue_redraw()

func _perform_ring_attack() -> void:
	if is_dead:
		return
	# Ring pulse or minion spawn
	queue_redraw()

func _draw() -> void:
	# Giant Mega-Mech Boss Chassis
	var base_col := Color(1.0, 0.1, 0.2, 1.0) if is_phase_two else Color(0.8, 0.1, 0.4, 1.0)
	var glow := Color(1.0, 0.2, 0.5, 0.5)
	
	# Massive octagon frame
	var points := PackedVector2Array([
		Vector2(32, 12),
		Vector2(12, 32),
		Vector2(-12, 32),
		Vector2(-32, 12),
		Vector2(-32, -12),
		Vector2(-12, -32),
		Vector2(12, -32),
		Vector2(32, -12)
	])
	draw_colored_polygon(points, base_col)
	draw_polyline(points, glow, 3.5, true)
	
	# Boss eye core
	var eye_col := Color(1.0, 0.9, 0.2, 1.0) if is_phase_two else Color.WHITE
	draw_circle(Vector2(6, 0), 8.0, eye_col)
