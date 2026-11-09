extends Area2D
class_name NanoChip

signal collected(value: int)

@export var chip_value: int = 1
@export var base_speed: float = 280.0

var _target: Node2D = null
var _current_speed: float = 0.0

func _ready() -> void:
	add_to_group("drops")
	collision_layer = 8 # Drops layer
	collision_mask = 2 # Player layer
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	# Geometric Procedural Amber Diamond with inner glow
	var amber := Color(1.0, 0.69, 0.0, 0.95)
	var glow := Color(1.0, 0.85, 0.3, 0.4)
	var points := PackedVector2Array([
		Vector2(0, -6),
		Vector2(5, 0),
		Vector2(0, 6),
		Vector2(-5, 0)
	])
	draw_colored_polygon(points, amber)
	draw_polyline(points, glow, 1.5, true)

func set_magnet_target(target: Node2D) -> void:
	_target = target
	_current_speed = base_speed

func _physics_process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var direction := (_target.global_position - global_position).normalized()
		# Accelerate towards target to prevent permanent trailing
		_current_speed += 400.0 * delta
		global_position += direction * _current_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect()

func _on_area_entered(_area: Area2D) -> void:
	pass

func collect() -> void:
	collected.emit(chip_value)
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.add_chips(chip_value)
	queue_free()
