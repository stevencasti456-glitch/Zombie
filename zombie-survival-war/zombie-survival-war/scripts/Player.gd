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

# Controles táctiles
var joystick: Node
var jump_button: Node
var crouch_button: Node
var shoot_button: Node

# ============================================================
# CREAR PERSONAJE HUMANOIDE (FASE 2.5)
# ============================================================
func create_humanoid_character() -> void:
	# Eliminar mesh cilindro anterior si existe
	var old_mesh = get_node_or_null("MeshInstance3D")
	if old_mesh:
		old_mesh.queue_free()
	
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
	
	# Crear personaje humanoide en vez de usar el mesh cilindro
	create_humanoid_character()
	
	# Configurar controles táctiles
	setup_touch_controls()
	
	# Configurar animación
	setup_animations()

func setup_touch_controls() -> void:
	var ui = get_node_or_null("UI")
	if ui:
		joystick = ui.get_node_or_null("Joystick")
		jump_button = ui.get_node_or_null("JumpButton")
		crouch_button = ui.get_node_or_null("CrouchButton")
		shoot_button = ui.get_node_or_null("ShootButton")
		
		if jump_button:
			jump_button.pressed.connect(_on_jump_pressed)
		if crouch_button:
			crouch_button.pressed.connect(_on_crouch_pressed)
		if shoot_button:
			shoot_button.pressed.connect(_on_shoot_pressed)

func setup_animations() -> void:
	# Aquí puedes agregar animaciones del personaje
	pass

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	
	# Manejar input
	handle_input(delta)
	
	# Mover personaje
	move_and_slide()
	
	# Actualizar cámara
	update_camera()

func handle_input(_delta: float) -> void:
	var input_dir = Vector3.ZERO
	
	# Input del joystick táctil
	if joystick and joystick.has_method("get_input"):
		var joy_input = joystick.get_input()
		input_dir.x = joy_input.x
		input_dir.z = joy_input.y
	else:
		# Input de teclado como fallback
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	
	input_dir = input_dir.normalized()
	
	# Calcular dirección relativa a la cámara
	var direction = (transform.basis * input_dir).normalized()
	
	# Aplicar movimiento
	if direction.length() > 0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func update_camera() -> void:
	if camera_pivot:
		# Posicionar el pivote de la cámara
		camera_pivot.global_position = global_position + Vector3(0, CAMERA_HEIGHT, 0)
		
		# Calcular posición de la cámara
		var camera_pos = camera_pivot.global_position - camera_pivot.global_transform.basis.z * CAMERA_DISTANCE
		camera.global_position = camera_pos
		
		# La cámara mira al jugador
		camera.look_at(global_position + Vector3(0, 1.5, 0), Vector3.UP)

func _on_jump_pressed() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _on_crouch_pressed() -> void:
	is_crouching = !is_crouching
	if is_crouching:
		# Reducir altura del personaje
		scale.y = 0.5
	else:
		scale.y = 1.0

func _on_shoot_pressed() -> void:
	if can_shoot:
		shoot()

func shoot() -> void:
	can_shoot = false
	get_tree().create_timer(shoot_cooldown).timeout.connect(func(): can_shoot = true)
	
	# Raycast desde la cámara
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = camera.global_position
	query.to = camera.global_position - camera.global_transform.basis.z * 100.0
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
