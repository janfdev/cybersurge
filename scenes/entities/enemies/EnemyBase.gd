extends CharacterBody2D
class_name EnemyBase

signal enemy_died(pos: Vector2, chip_value: int)

@export var max_health: int = 20
@export var move_speed: float = 160.0
@export var contact_damage: int = 10
@export var chip_drop_value: int = 1
@export var knockback_resistance: float = 0.0

var current_health: int = 20
var is_dead: bool = false
var _target_player: Node2D = null
var _knockback: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4 # Enemies layer
	collision_mask = 3 # World & Player
	current_health = max_health
	_find_player()
	queue_redraw()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target_player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not _target_player or not is_instance_valid(_target_player):
		_find_player()
		
	# Movement towards player
	var dir := Vector2.ZERO
	if _target_player and is_instance_valid(_target_player):
		dir = (_target_player.global_position - global_position).normalized()
		rotation = lerp_angle(rotation, dir.angle(), 10.0 * delta)
		
	# Apply knockback decay
	if _knockback.length_squared() > 1.0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, 800.0 * delta)
	else:
		velocity = dir * move_speed
		
	move_and_slide()
	
	# Check contact with player
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage)

func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_health -= amount
	# Apply knockback scaled by resistance
	if hit_direction != Vector2.ZERO and knockback_resistance < 1.0:
		_knockback = hit_direction.normalized() * 250.0 * (1.0 - knockback_resistance)
		
	# Flash visual
	modulate = Color(2.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
		
	if current_health <= 0:
		_die()

func _die() -> void:
	is_dead = true
	enemy_died.emit(global_position, chip_drop_value)
	if is_inside_tree():
		var gd = get_node_or_null("/root/GameData")
		if gd and gd.has_method("register_kill"):
			gd.register_kill()
		_spawn_chip()
	queue_free()

func _spawn_chip() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if not tree:
		return
	var chip_scene = load("res://scenes/entities/drops/NanoChip.tscn")
	if chip_scene:
		var chip = chip_scene.instantiate()
		chip.global_position = global_position
		chip.chip_value = chip_drop_value
		var scene_root = tree.current_scene if tree.current_scene else tree.root
		if scene_root:
			scene_root.add_child(chip)
