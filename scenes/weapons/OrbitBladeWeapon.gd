extends "res://scenes/weapons/WeaponBase.gd"
class_name OrbitBladeWeapon

@export var orbit_radius: float = 90.0
@export var rotation_speed: float = 4.0

var _current_angle: float = 0.0
var _blade_area: Area2D = null

func _init() -> void:
	weapon_name = "Orbiting Blade"
	base_damage = 30
	cooldown = 0.2

func _ready() -> void:
	super._ready()
	_blade_area = Area2D.new()
	_blade_area.collision_layer = 0
	_blade_area.collision_mask = 4 # Enemies
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	_blade_area.add_child(col)
	
	_blade_area.body_entered.connect(_on_blade_hit)
	add_child(_blade_area)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_current_angle += rotation_speed * delta
	if _blade_area:
		_blade_area.position = Vector2(cos(_current_angle), sin(_current_angle)) * orbit_radius
	queue_redraw()

func _draw() -> void:
	if _blade_area:
		# Draw neon cyan orbiting blade with energy trail
		var cyan := Color(0.0, 0.94, 1.0, 0.9)
		var glow := Color(0.0, 0.94, 1.0, 0.3)
		var center := _blade_area.position
		draw_circle(center, 12.0, glow)
		draw_circle(center, 6.0, cyan)
		draw_circle(center, 3.0, Color.WHITE)

func _on_blade_hit(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(base_damage)
