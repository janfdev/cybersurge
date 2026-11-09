extends CharacterBody2D
class_name Player

signal health_changed(current: int, max_hp: int)
signal player_died()

@export var max_health: int = 100
@export var move_speed: float = 240.0
@export var invulnerability_duration: float = 0.2

var current_health: int = 100
var _invulnerable_timer: float = 0.0
var _detected_enemies: Array[Node2D] = []

@onready var target_sensor: Area2D = $TargetSensor
@onready var magnet_sensor: Area2D = $MagnetSensor

func _ready() -> void:
	add_to_group("player")
	var gd = get_node_or_null("/root/GameData")
	if gd:
		max_health = gd.player_max_hp
		move_speed = gd.player_speed
	current_health = max_health
	
	if target_sensor:
		target_sensor.body_entered.connect(_on_target_sensor_entered)
		target_sensor.body_exited.connect(_on_target_sensor_exited)
	if magnet_sensor:
		magnet_sensor.area_entered.connect(_on_magnet_area_entered)
	queue_redraw()

func _draw() -> void:
	# Procedural Neon Cyan Cyborg Agent Silhouette
	var cyan := Color(0.0, 0.94, 1.0, 1.0)
	var glow := Color(0.0, 0.94, 1.0, 0.4)
	var white := Color(1.0, 1.0, 1.0, 0.9)
	
	# Arrowhead / Delta fighter shape
	var points := PackedVector2Array([
		Vector2(14, 0),
		Vector2(-10, -10),
		Vector2(-4, 0),
		Vector2(-10, 10)
	])
	draw_colored_polygon(points, cyan)
	draw_polyline(points, glow, 2.0, true)
	# Center core
	draw_circle(Vector2(2, 0), 3.0, white)

func _physics_process(delta: float) -> void:
	# Invulnerability timer tick
	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
		
	# WASD / Arrow movement
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO and InputMap.has_action("move_left"):
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
	velocity = dir * move_speed
	move_and_slide()
	
	# Rotate towards closest enemy or movement direction
	var closest := get_closest_enemy()
	if closest and is_instance_valid(closest):
		rotation = lerp_angle(rotation, (closest.global_position - global_position).angle(), 15.0 * delta)
	elif velocity.length_squared() > 10.0:
		rotation = lerp_angle(rotation, velocity.angle(), 10.0 * delta)

func take_damage(amount: int) -> void:
	if amount <= 0 or _invulnerable_timer > 0.0 or current_health <= 0:
		return
		
	_invulnerable_timer = invulnerability_duration
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Flash effect
	modulate = Color(1.5, 0.5, 0.5, 1.0)
	var tween := create_tween()
	if tween:
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
		
	if current_health <= 0:
		player_died.emit()

func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var min_dist: float = INF
	
	# Clean up invalid references
	var valid_enemies: Array[Node2D] = []
	for enemy in _detected_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			valid_enemies.append(enemy)
			var dist := global_position.distance_squared_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy
	_detected_enemies = valid_enemies
	return closest

func _on_target_sensor_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not _detected_enemies.has(body):
		_detected_enemies.append(body)

func _on_target_sensor_exited(body: Node2D) -> void:
	_detected_enemies.erase(body)

func _on_magnet_area_entered(area: Area2D) -> void:
	if area.has_method("set_magnet_target"):
		area.set_magnet_target(self)
