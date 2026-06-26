extends CharacterBody3D

# ============================================================
# SISTEMA DE VIDA
# ============================================================
@export var max_health: int = 100
var current_health: int = 100

# ============================================================
# SISTEMA DE DISPARO - FASE 3
# ============================================================
@export var SHOOT_DAMAGE: int = 25
@export var SHOOT_COOLDOWN: float = 0.5
@export var SHOOT_RANGE: float = 50.0

var can_shoot: bool = true
var shoot_timer: float = 0.0

# ============================================================
# MOVIMIENTO
# ============================================================
const SPEED = 5.0
const CROUCH_SPEED = 2.5
const JUMP_VELOCITY = 6.5
const GRAVITY = 15.0
const TOUCH_SENSITIVITY = 0.005

# ============================================================
# REFERENCIAS
# ============================================================
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D

var move_input: Vector2 = Vector2.ZERO
var touch_look_input: Vector2 = Vector2.ZERO
var left_finger_index: int = -1
var right_finger_index: int = -1
var left_joystick_center: Vector2 = Vector2.ZERO

var is_crouching: bool = false
var current_speed: float = SPEED

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	current_speed = SPEED
	current_health = max_health
	print("JUGADOR LISTO - Vida: ", current_health, "/", max_health)
	print("SISTEMA DE DISPARO LISTO - Daño: ", SHOOT_DAMAGE, " | Cooldown: ", SHOOT_COOLDOWN, "s")

# ============================================================
# SISTEMA DE VIDA
# ============================================================
func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
	print("DAÑO RECIBIDO: -", amount, " | Vida: ", current_health, "/", max_health)
	if current_health == 0:
		die()

func heal(amount: int) -> void:
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	print("CURACION: +", amount, " | Vida: ", current_health, "/", max_health)

func get_health() -> int:
	return current_health

func is_alive() -> bool:
	return current_health > 0

func die() -> void:
	print("JUGADOR MUERTO")
	move_input = Vector2.ZERO
	set_physics_process(false)

# ============================================================
# SISTEMA DE DISPARO - CORREGIDO
# ============================================================

func _on_shoot_button_pressed() -> void:
	shoot()

func shoot() -> void:
	if not can_shoot:
		print("DISPARO EN COOLDOWN")
		return
	
	if not is_alive():
		return
	
	can_shoot = false
	shoot_timer = 0.0
	
	print("💥 ¡DISPARO!")
	
	# ✅ CORREGIDO: RayCast que IGNORA al jugador
	var space_state = get_world_3d().direct_space_state
	
	# Punto de inicio: ligeramente adelante de la cámara para no tocarnos
	var camera_forward = -camera_3d.global_transform.basis.z.normalized()
	var origin = camera_3d.global_position + camera_forward * 1.5  # 1.5 metros adelante de la cámara
	var end = origin + camera_forward * SHOOT_RANGE
	
	var query = PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = end
	query.collision_mask = 1
	query.exclude = [self]  # ✅ IGNORAR al jugador (this)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_object = result.collider
		var hit_point = result.position
		
		print("Impacto en: ", hit_object.name, " | Punto: ", hit_point)
		
		# Verificar si es zombie
		if hit_object.is_in_group("Zombie") or "Zombie" in hit_object.name:
			if hit_object.has_method("take_damage"):
				hit_object.take_damage(SHOOT_DAMAGE)
				print("💀 Zombie herido! Daño: ", SHOOT_DAMAGE)
			else:
				print("El zombie no tiene metodo take_damage")
		else:
			print("Impacto en objeto: ", hit_object.name)
	else:
		print("Disparo al aire")

# ============================================================
# FISICA
# ============================================================
func _physics_process(delta: float) -> void:
	# Cooldown de disparo
	if not can_shoot:
		shoot_timer += delta
		if shoot_timer >= SHOOT_COOLDOWN:
			can_shoot = true
			shoot_timer = 0.0
	
	# Gravedad
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# Movimiento
	var direction := Vector3.ZERO
	if move_input.length() > 0.0:
		var aim: Basis = global_transform.basis
		direction = (aim.z * move_input.y + aim.x * move_input.x).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()

# ============================================================
# CONTROLES TACTILES
# ============================================================
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			if event.position.x > get_viewport().size.x / 2 and right_finger_index == -1:
				right_finger_index = event.index
			elif event.position.x <= get_viewport().size.x / 2 and left_finger_index == -1:
				left_finger_index = event.index
				left_joystick_center = event.position
		else:
			if event.index == right_finger_index:
				right_finger_index = -1
				touch_look_input = Vector2.ZERO
			elif event.index == left_finger_index:
				left_finger_index = -1
				move_input = Vector2.ZERO
	
	if event is InputEventScreenDrag:
		if event.index == right_finger_index:
			touch_look_input = event.relative
			rotate_y(-touch_look_input.x * TOUCH_SENSITIVITY)
			camera_pivot.rotate_x(-touch_look_input.y * TOUCH_SENSITIVITY)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-45), deg_to_rad(30))
		elif event.index == left_finger_index:
			var drag_vector = event.position - left_joystick_center
			var max_range = 100.0
			move_input = drag_vector.limit_length(max_range) / max_range

# ============================================================
# BOTONES UI
# ============================================================
func _on_jump_button_pressed() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _on_crouch_button_button_down() -> void:
	if not is_crouching:
		is_crouching = true
		current_speed = CROUCH_SPEED
		scale.y = 0.5

func _on_crouch_button_button_up() -> void:
	if is_crouching:
		is_crouching = false
		current_speed = SPEED
		scale.y = 1.0

# ============================================================
# TECLAS DE PRUEBA (PC)
# ============================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			take_damage(10)
		elif event.keycode == KEY_E:
			heal(15)
		elif event.keycode == KEY_F:
			shoot()
		elif event.keycode == KEY_R:
			print("ESTADO: ", current_health, "/", max_health)
