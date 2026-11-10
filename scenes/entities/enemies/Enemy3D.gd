extends CharacterBody3D
class_name Enemy3D

signal died(enemy: Enemy3D)

@export var max_hp: int = 100
@export var move_speed: float = 4.8
@export var damage_per_hit: int = 15
@export var attack_rate: float = 0.8
@export var chips_reward: int = 10

var current_hp: int = 100
var is_dead: bool = false
var can_attack: bool = true
var target_player: CharacterBody3D = null

@onready var body_mesh: MeshInstance3D = $Visuals/BodyMesh
@onready var head_mesh: MeshInstance3D = $Visuals/HeadMesh
@onready var eye_light: OmniLight3D = $Visuals/EyeLight

func _ready() -> void:
	current_hp = max_hp
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		return
		
	# Look at player smoothly (keep Y level)
	var target_pos := target_player.global_position
	var look_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	if global_position.distance_squared_to(look_target) > 0.01:
		look_at(look_target, Vector3.UP)
		
	# Move towards player
	var diff := target_pos - global_position
	var dist := diff.length()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if dist > 1.8:
		var dir := diff.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		if can_attack:
			_attack_player()
			
	move_and_slide()

func _attack_player() -> void:
	can_attack = false
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(damage_per_hit)
		
	# Attack pulse animation
	var tw := create_tween()
	tw.tween_property($Visuals, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	tw.tween_property($Visuals, "scale", Vector3.ONE, 0.1)
	
	await get_tree().create_timer(attack_rate).timeout
	can_attack = true

func take_hit(damage: int, is_headshot: bool) -> void:
	if is_dead:
		return
		
	current_hp -= damage
	_flash_damage(is_headshot)
	
	if current_hp <= 0:
		die()

func _flash_damage(is_headshot: bool) -> void:
	var flash_mat := StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color(1.0, 0.9, 0.2) if is_headshot else Color(1.0, 0.1, 0.2)
	
	body_mesh.material_override = flash_mat
	await get_tree().create_timer(0.08).timeout
	body_mesh.material_override = null

func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(self)
	
	# Death collapse & reward chips
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.add_chips(chips_reward)
		gd.register_kill()
		
	collision_layer = 0
	collision_mask = 0
	
	var tw := create_tween()
	tw.tween_property($Visuals, "scale", Vector3(1.2, 0.1, 1.2), 0.2)
	tw.tween_property($Visuals, "position:y", -0.4, 0.2)
	await tw.finished
	queue_free()
