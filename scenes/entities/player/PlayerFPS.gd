extends CharacterBody3D
class_name PlayerFPS

signal health_changed(current: int, max_hp: int)
signal player_died()
signal ammo_changed(current: int, max_mag: int, reserve: int)
signal hit_registered(is_headshot: bool)

@export var move_speed: float = 8.5
@export var sprint_speed: float = 12.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.0022
@export var max_health: int = 100

var current_health: int = 100
var is_dead: bool = false

# Gun specs (Point Blank Style Pistol)
var mag_capacity: int = 12
var current_ammo: int = 12
var reserve_ammo: int = 72
var fire_rate: float = 0.18 # seconds per shot
var damage_body: int = 35
var damage_head: int = 100
var can_fire: bool = true
var is_reloading: bool = false
var reload_time: float = 1.3

# Recoil & Bobbing variables
var _recoil_rot: float = 0.0
var _recoil_pos: Vector3 = Vector3.ZERO
var _bob_timer: float = 0.0
var _orig_gun_pos: Vector3 = Vector3(0.28, -0.25, -0.55)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var gun_pivot: Node3D = $Head/Camera3D/GunPivot
@onready var gun_mesh: Node3D = $Head/Camera3D/GunPivot/GunModel
@onready var muzzle_flash: OmniLight3D = $Head/Camera3D/GunPivot/GunModel/MuzzleFlash
@onready var muzzle_marker: Marker3D = $Head/Camera3D/GunPivot/GunModel/MuzzleMarker
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D

func _ready() -> void:
	current_health = max_health
	current_ammo = mag_capacity
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_build_procedural_gun_model()
	health_changed.emit(current_health, max_health)
	ammo_changed.emit(current_ammo, mag_capacity, reserve_ammo)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
		
	# Mouse look in WebAssembly / Desktop: handles both relative motion and captured state
	if event is InputEventMouseMotion:
		# If mouse captured OR if user is clicking & dragging, rotate camera
		var is_captured := (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)
		var is_dragging := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if is_captured or is_dragging:
			rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
		
	# Arrow keys / Q-E keys fallback for camera rotation (ensures aiming always works anywhere)
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Q):
		rotate_y(0.04)
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_E):
		rotate_y(-0.04)
	if Input.is_key_pressed(KEY_UP):
		head.rotate_x(0.03)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	elif Input.is_key_pressed(KEY_DOWN):
		head.rotate_x(-0.03)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
		
	# Capture/release mouse on click or escape
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		try_fire()
	elif event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# WASD Movement direction
	var move_x := 0.0
	var move_z := 0.0
	if Input.is_key_pressed(KEY_A):
		move_x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move_x += 1.0
	if Input.is_key_pressed(KEY_W):
		move_z -= 1.0
	if Input.is_key_pressed(KEY_S):
		move_z += 1.0
		
	var input_dir := Vector2(move_x, move_z).normalized()
	# GDQuest / scenario-godot-3d-world principle: zero Y before normalizing
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting: bool = Input.is_key_pressed(KEY_SHIFT)
	var speed: float = sprint_speed if is_sprinting else move_speed

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Camera / Gun Bobbing
		_bob_timer += delta * (14.0 if is_sprinting else 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
		_bob_timer = move_toward(_bob_timer, 0.0, delta * 8.0)

	move_and_slide()
	_process_gun_bob_and_recoil(delta, direction != Vector3.ZERO)
	
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			try_reload()

func try_fire() -> void:
	if not can_fire or is_reloading or is_dead:
		return
		
	if current_ammo <= 0:
		try_reload()
		return
		
	can_fire = false
	current_ammo -= 1
	ammo_changed.emit(current_ammo, mag_capacity, reserve_ammo)
	
	# Apply visual recoil (snappy kickback and muzzle rise)
	_recoil_rot = clamp(_recoil_rot + 0.18, 0.0, 0.35)
	_recoil_pos.z = clamp(_recoil_pos.z + 0.06, 0.0, 0.12)
	_flash_muzzle()
	
	# Hitscan Shooting
	_fire_hitscan()
	
	# Rate of fire delay
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _fire_hitscan() -> void:
	if not raycast:
		return
	raycast.force_raycast_update()
	
	var hit_target := raycast.get_collider()
	var hit_pos := raycast.get_collision_point() if raycast.is_colliding() else (head.global_position - head.global_transform.basis.z * 100.0)
	
	# Spawn neon bullet tracer line
	_spawn_bullet_tracer(muzzle_marker.global_position, hit_pos)
	
	if raycast.is_colliding() and hit_target:
		var is_head: bool = false
		if hit_target.has_method("take_hit"):
			# Check headshot based on hit height relative to enemy position
			if hit_pos.y >= (hit_target.global_position.y + 1.35):
				is_head = true
				hit_target.take_hit(damage_head, true)
			else:
				hit_target.take_hit(damage_body, false)
			hit_registered.emit(is_head)
			_spawn_hit_spark(hit_pos, true)
		else:
			_spawn_hit_spark(hit_pos, false)

func try_reload() -> void:
	if is_reloading or current_ammo == mag_capacity or reserve_ammo <= 0:
		return
		
	is_reloading = true
	# Lower gun animation & reset recoil
	_recoil_rot = 0.0
	_recoil_pos = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(gun_pivot, "position:y", -0.35, reload_time * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(gun_pivot, "position:y", 0.0, reload_time * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(reload_time).timeout
	var needed: int = mag_capacity - current_ammo
	var reload_amount: int = mini(needed, reserve_ammo)
	current_ammo += reload_amount
	reserve_ammo -= reload_amount
	is_reloading = false
	ammo_changed.emit(current_ammo, mag_capacity, reserve_ammo)

func _process_gun_bob_and_recoil(delta: float, is_moving: bool) -> void:
	if not gun_mesh:
		return
	# Recover from recoil with smooth exponential decay
	_recoil_rot = lerp(_recoil_rot, 0.0, delta * 14.0)
	_recoil_pos = _recoil_pos.lerp(Vector3.ZERO, delta * 14.0)
	
	# Bobbing
	var bob_x := sin(_bob_timer) * 0.012 if is_moving else 0.0
	var bob_y := cos(_bob_timer * 2.0) * 0.012 if is_moving else 0.0
	
	gun_mesh.position = _orig_gun_pos + _recoil_pos + Vector3(bob_x, bob_y, 0)
	gun_mesh.rotation = Vector3(_recoil_rot, 0.0, -bob_x * 1.5)

func _flash_muzzle() -> void:
	if muzzle_flash:
		muzzle_flash.visible = true
		await get_tree().create_timer(0.04).timeout
		muzzle_flash.visible = false

func _spawn_bullet_tracer(from: Vector3, to: Vector3) -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.0, 0.95, 1.0, 0.85)
	mi.material_override = mat
	
	get_parent().add_child(mi)
	
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()
	
	var tw := get_tree().create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.1)
	tw.tween_callback(mi.queue_free)

func _spawn_hit_spark(pos: Vector3, is_enemy: bool) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	mi.mesh = sphere
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.1, 0.3) if is_enemy else Color(1.0, 0.8, 0.2)
	mi.material_override = mat
	mi.global_position = pos
	
	get_parent().add_child(mi)
	var tw := get_tree().create_tween()
	tw.tween_property(mi, "scale", Vector3.ZERO, 0.15)
	tw.tween_callback(mi.queue_free)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	
	# Camera damage punch
	head.rotation.z = deg_to_rad(randf_range(-3.0, 3.0))
	
	if current_health <= 0:
		is_dead = true
		player_died.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _build_procedural_gun_model() -> void:
	# Build Point Blank tactical cyber pistol using clean box primitives
	# Slide / Barrel
	var slide := MeshInstance3D.new()
	var slide_mesh := BoxMesh.new()
	slide_mesh.size = Vector3(0.065, 0.085, 0.36)
	slide.mesh = slide_mesh
	
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.12, 0.14, 0.18)
	dark_mat.metallic = 0.85
	dark_mat.roughness = 0.2
	slide.material_override = dark_mat
	gun_mesh.add_child(slide)
	
	# Neon Laser Sight / Accent Strip
	var strip := MeshInstance3D.new()
	var strip_mesh := BoxMesh.new()
	strip_mesh.size = Vector3(0.07, 0.015, 0.30)
	strip.mesh = strip_mesh
	strip.position = Vector3(0, 0.045, 0.02)
	
	var cyan_glow := StandardMaterial3D.new()
	cyan_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cyan_glow.albedo_color = Color(0.0, 0.95, 1.0)
	strip.material_override = cyan_glow
	gun_mesh.add_child(strip)
	
	# Iron Sights (Front & Rear Pins for Authentic Aiming)
	var front_sight := MeshInstance3D.new()
	var front_sight_mesh := BoxMesh.new()
	front_sight_mesh.size = Vector3(0.012, 0.025, 0.015)
	front_sight.mesh = front_sight_mesh
	front_sight.position = Vector3(0, 0.055, -0.16)
	var front_sight_mat := StandardMaterial3D.new()
	front_sight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	front_sight_mat.albedo_color = Color(0.0, 1.0, 0.4) # Glowing green front post
	front_sight.material_override = front_sight_mat
	gun_mesh.add_child(front_sight)
	
	var rear_sight_left := MeshInstance3D.new()
	var rear_sight_left_mesh := BoxMesh.new()
	rear_sight_left_mesh.size = Vector3(0.012, 0.02, 0.015)
	rear_sight_left.mesh = rear_sight_left_mesh
	rear_sight_left.position = Vector3(-0.02, 0.055, 0.16)
	var rear_sight_mat := StandardMaterial3D.new()
	rear_sight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rear_sight_mat.albedo_color = Color(1.0, 0.2, 0.2) # Glowing red rear notch
	rear_sight_left.material_override = rear_sight_mat
	gun_mesh.add_child(rear_sight_left)
	
	var rear_sight_right := MeshInstance3D.new()
	var rear_sight_right_mesh := BoxMesh.new()
	rear_sight_right_mesh.size = Vector3(0.012, 0.02, 0.015)
	rear_sight_right.mesh = rear_sight_right_mesh
	rear_sight_right.position = Vector3(0.02, 0.055, 0.16)
	rear_sight_right.material_override = rear_sight_mat
	gun_mesh.add_child(rear_sight_right)
	
	# Muzzle Tip
	var muzzle := MeshInstance3D.new()
	var muzzle_mesh := BoxMesh.new()
	muzzle_mesh.size = Vector3(0.05, 0.05, 0.04)
	muzzle.mesh = muzzle_mesh
	muzzle.position = Vector3(0, 0.01, -0.19)
	var muzzle_mat := StandardMaterial3D.new()
	muzzle_mat.albedo_color = Color(0.05, 0.05, 0.05)
	muzzle.material_override = muzzle_mat
	gun_mesh.add_child(muzzle)
	
	# Grip
	var grip := MeshInstance3D.new()
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.055, 0.20, 0.09)
	grip.mesh = grip_mesh
	grip.position = Vector3(0, -0.12, 0.08)
	grip.rotation.x = deg_to_rad(15.0)
	
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.06, 0.07, 0.09)
	grip_mat.roughness = 0.8
	grip.material_override = grip_mat
	gun_mesh.add_child(grip)
	
	# Trigger Guard
	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.03, 0.08, 0.08)
	guard.mesh = guard_mesh
	guard.position = Vector3(0, -0.06, 0.01)
	guard.material_override = dark_mat
	gun_mesh.add_child(guard)
