extends CharacterBody3D

@export var SPEED: float = 5.0
@export var JUMP_VELOCITY: float = 8.0
@export var SENSITIVITY: float = 0.005
@export var CAMERA_DISTANCE: float = 8.0
@export var CAMERA_HEIGHT: float = 4.0

# Vida del jugador
@export var max_health: int = 100
var health: int = 100

# Referencias
var camera: Camera3D
var camera_pivot: Node3D
var mesh_instance: Node3D

# Estado
var can_shoot: bool = true
var shoot_cooldown: float = 0.5
var is_crouching: bool = false

# Controles táctiles - RESTAURADOS
var move_input: Vector2 = Vector2.ZERO
var touch_look_input: Vector2 = Vector2.ZERO
var left_finger_index: int = -1
var right_finger_index: int = -1
var left_joystick_center: Vector2 = Vector2.ZERO

# ============================================================
# CREAR PERSONAJE HUMANOIDE (FASE 2.5)
# ============================================================
func create_humanoid_character() -> void:
	# Eliminar mesh cilindro anterior si existe
	var old_mesh = get_node_or_null("MeshInstance3D")
	if old_mesh:
		remove_child(old_mesh)
		old_mesh.free()
	
	# Crear contenedor del personaje
	var character = Node3D.new()
	character.name = "CharacterModel"
	add_child(character)
	
	# Materiales
	var skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.9, 0.7, 0.5)
	skin_mat.roughness = 0.8
	
	var shirt_mat = StandardMaterial3D.new()
	shirt_mat.albedo_color = Color(0.2, 0.3, 0.5)
	shirt_mat.roughness = 0.7
	
	var pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.15, 0.15, 0.2)
	pants_mat.roughness = 0.9
	
	var boots_mat = StandardMaterial3D.new()
	boots_mat.albedo_color = Color(0.1, 0.08, 0.05)
	boots_mat.roughness = 0.6
	
	# Cabeza
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head.mesh = head_mesh
	head.set_surface_override_material(0, skin_mat)
	head.position = Vector3(0, 1.7, 0)
	character.add_child(head)
	
	# Torso
	var torso = MeshInstance3D.new()
	var torso_mesh = CapsuleMesh.new()
	torso_mesh.radius = 0.3
	torso_mesh.height = 0.8
	torso.mesh = torso_mesh
	torso.set_surface_override_material(0, shirt_mat)
	torso.position = Vector3(0, 1.0, 0)
	character.add_child(torso)
	
	# Brazos
	var arm_mesh = CylinderMesh.new()
	arm_mesh.top_radius = 0.08
	arm_mesh.bottom_radius = 0.07
	arm_mesh.height = 0.7
	
	var left_arm = MeshInstance3D.new()
	left_arm.mesh = arm_mesh
	left_arm.set_surface_override_material(0, skin_mat)
	left_arm.position = Vector3(-0.4, 1.2, 0)
	left_arm.rotation.z = 0.2
	character.add_child(left_arm)
	
	var right_arm = MeshInstance3D.new()
	right_arm.mesh = arm_mesh
	right_arm.set_surface_override_material(0, skin_mat)
	right_arm.position = Vector3(0.4, 1.2, 0)
	right_arm.rotation.z = -0.2
	character.add_child(right_arm)
	
	# Piernas
	var leg_mesh = CylinderMesh.new()
	leg_mesh.top_radius = 0.12
	leg_mesh.bottom_radius = 0.1
	leg_mesh.height = 0.9
	
	var left_leg = MeshInstance3D.new()
	left_leg.mesh = leg_mesh
	left_leg.set_surface_override_material(0, pants_mat)
	left_leg.position = Vector3(-0.15, 0.45, 0)
	character.add_child(left_leg)
	
	var right_leg = MeshInstance3D.new()
	right_leg.mesh = leg_mesh
	right_leg.set_surface_override_material(0, pants_mat)
	right_leg.position = Vector3(0.15, 0.45, 0)
	character.add_child(right_leg)
	
	# Botas
	var boot_mesh = CylinderMesh.new()
	boot_mesh.top_radius = 0.11
	boot_mesh.bottom_radius = 0.13
	boot_mesh.height = 0.3
	
	var left_boot = MeshInstance3D.new()
	left_boot.mesh = boot_mesh
	left_boot.set_surface_override_material(0, boots_mat)
	left_boot.position = Vector3(-0.15, 0.15, 0)
	character.add_child(left_boot)
	
	var right_boot = MeshInstance3D.new()
	right_boot.mesh = boot_mesh
	right_boot.set_surface_override_material(0, boots_mat)
	right_boot.position = Vector3(0.15, 0.15, 0)
	character.add_child(right_boot)
	
	# Rifle
	var rifle = MeshInstance3D.new()
	var rifle_mesh = BoxMesh.new()
	rifle_mesh.size = Vector3(0.08, 0.15, 0.6)
	rifle.mesh = rifle_mesh
	var rifle_mat = StandardMaterial3D.new()
	rifle_mat.albedo_color = Color(0.15, 0.15, 0.15)
	rifle_mat.roughness = 0.4
	rifle_mat.metallic = 0.8
	rifle.set_surface_override_material(0, rifle_mat)
	rifle.position = Vector3(0.25, 0.9, 0.4)
	rifle.rotation.x = -0.2
	character.add_child(rifle)
	
	# Guardar referencia
	mesh_instance = character

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	velocity = Vector3.ZERO
	health = max_health
	camera = get_node("CameraPivot/Camera3D")
	camera_pivot = get_node("CameraPivot")
	
	# Crear personaje humanoide
	create_humanoid_character()
	
	# Configurar animación
	setup_animations()
	
	# DEBUG: Verificar posición inicial
	print("DEBUG: Posición inicial Y: ", global_position.y)
	print("DEBUG: is_on_floor: ", is_on_floor())

func setup_animations() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	
	# Manejar input
	handle_input(delta)
	
	# Mover personaje
	move_and_slide()
	
	# Actualizar cámara
	update_camera()
	
	# DEBUG: Verificar si está cayendo
	if global_position.y < 10:
		print("DEBUG: Personaje cayendo! Y: ", global_position.y)

# ============================================================
# INPUT - RESTAURADO PARA MÓVIL Y PC
# ============================================================
func handle_input(_delta: float) -> void:
	var input_dir = Vector3.ZERO
	
	# --- MÓVIL: Joystick virtual por detección de pantalla ---
	if move_input.length() > 0:
		input_dir.x = move_input.x
		input_dir.z = move_input.y
	
	# --- PC: Teclado como fallback ---
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	
	input_dir = input_dir.normalized()
	
	# --- MOVIMIENTO RELATIVO A LA CÁMARA (intuitivo) ---
	if input_dir.length() > 0:
		# Obtener dirección de la cámara (plana, sin inclinación)
		var camera_forward = -camera.global_transform.basis.z
		camera_forward.y = 0
		camera_forward = camera_forward.normalized()
		
		var camera_right = camera.global_transform.basis.x
		camera_right.y = 0
		camera_right = camera_right.normalized()
		
		# Combinar: joystick adelante = adelante de la cámara
		var direction = (camera_forward * -input_dir.z + camera_right * input_dir.x).normalized()
		
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# ← CAMBIO ELIMINADO: NO rotar personaje automáticamente
		# El personaje siempre mira hacia adelante de la cámara
		# O si quieres que mire hacia donde camina, hazlo suave y solo cuando no estás rotando cámara
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func update_camera() -> void:
	if camera_pivot:
		# Solo mover el pivote a la posición del jugador (sin rotar)
		camera_pivot.global_position = global_position + Vector3(0, CAMERA_HEIGHT, 0)
		# La cámara mantiene su posición relativa al pivote (definida en la escena)

# ============================================================
# BOTONES UI - NOMBRES COMPATIBLES CON main.tscn
# ============================================================
func _on_jump_button_pressed() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _on_crouch_button_button_down() -> void:
	if not is_crouching:
		is_crouching = true
		scale.y = 0.5

func _on_crouch_button_button_up() -> void:
	if is_crouching:
		is_crouching = false
		scale.y = 1.0

func _on_shoot_button_pressed() -> void:
	if can_shoot:
		shoot()

func shoot() -> void:
	can_shoot = false
	get_tree().create_timer(shoot_cooldown).timeout.connect(func(): can_shoot = true)
	
	# Raycast desde la cámara con offset
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	
	var camera_forward = -camera.global_transform.basis.z.normalized()
	var origin = camera.global_position + camera_forward * 1.5
	query.from = origin
	query.to = origin + camera_forward * 100.0
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.has_method("take_damage"):
			collider.take_damage(25)

func take_damage(amount: int) -> void:
	health -= amount
	if health < 0:
		health = 0
	print("Jugador herido! Vida: ", health, "/", max_health)
	
	if health <= 0:
		die()

func die() -> void:
	print("JUGADOR MUERE")
	set_physics_process(false)
	
	# Animación de muerte
	var tween = create_tween()
	tween.tween_property(self, "rotation:x", PI / 2, 0.5)
	await tween.finished
	
	# Esperar y reiniciar
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func get_health() -> int:
	return health

# ============================================================
# CONTROLES TÁCTILES - CORREGIDOS
# ============================================================
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			# ← CAMBIO: Dedo izquierdo = mover (mitad izquierda, TODA la altura)
			if event.position.x <= get_viewport().size.x / 2 and left_finger_index == -1:
				left_finger_index = event.index
				left_joystick_center = event.position
			# ← CAMBIO: Dedo derecho = mirar (mitad derecha, TODA la altura)
			elif event.position.x > get_viewport().size.x / 2 and right_finger_index == -1:
				right_finger_index = event.index
		else:
			# Soltar dedo
			if event.index == right_finger_index:
				right_finger_index = -1
				touch_look_input = Vector2.ZERO
			elif event.index == left_finger_index:
				left_finger_index = -1
				move_input = Vector2.ZERO
	
	if event is InputEventScreenDrag:
		# Dedo derecho arrastrando = rotar cámara
		if event.index == right_finger_index:
			touch_look_input = event.relative
			rotate_y(-touch_look_input.x * SENSITIVITY)
			if camera_pivot:
				camera_pivot.rotate_x(-touch_look_input.y * SENSITIVITY)
				camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-45), deg_to_rad(30))
		# Dedo izquierdo arrastrando = joystick virtual
		elif event.index == left_finger_index:
			var drag_vector = event.position - left_joystick_center
			var max_range = 100.0
			move_input = drag_vector.limit_length(max_range) / max_range
