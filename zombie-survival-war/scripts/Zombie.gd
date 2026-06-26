extends CharacterBody3D

@export var SPEED: float = 3.5
@export var DAMAGE: int = 15
@export var ROTATION_SPEED: float = 8.0
@export var DETECTION_RANGE: float = 15.0
@export var ATTACK_RANGE: float = 1.8
@export var ATTACK_COOLDOWN: float = 1.5

@export var max_health: int = 50
var current_health: int = 50

var nav_agent: NavigationAgent3D
var mesh_instance: MeshInstance3D

var player: CharacterBody3D = null
var path_update_time: float = 0.0
var path_update_interval: float = 0.5
var attack_timer: float = 0.0
var can_attack: bool = true
var is_attacking: bool = false
var original_color: Color = Color(0.186, 0.392, 0.241)

var health_bar_bg: MeshInstance3D
var health_bar_fill: MeshInstance3D
var health_bar_container: Node3D

var game_manager: Node = null

func _ready() -> void:
	# Buscar nodos hijos
	nav_agent = get_node_or_null("NavigationAgent3D")
	mesh_instance = get_node_or_null("MeshInstance3D")
	
	await get_tree().create_timer(0.5).timeout
	
	player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_tree().get_root().find_child("Player", true, false)
	
	game_manager = get_tree().get_first_node_in_group("GameManager")
	if game_manager == null:
		game_manager = get_tree().get_root().find_child("GameManager", true, false)
	
	if player != null and is_instance_valid(player):
		print("ZOMBIE: Jugador encontrado")
	else:
		push_error("ZOMBIE: No se encontro el jugador")
		return
	
	current_health = max_health
	
	create_health_bar()
	update_health_bar()
	
	if nav_agent:
		nav_agent.path_desired_distance = 1.5
		nav_agent.target_desired_distance = ATTACK_RANGE
		nav_agent.avoidance_enabled = false
	
	if mesh_instance:
		var mat = mesh_instance.get_surface_override_material(0)
		if mat:
			original_color = mat.albedo_color

func create_health_bar() -> void:
	health_bar_container = Node3D.new()
	health_bar_container.name = "HealthBar"
	health_bar_container.position = Vector3(0, 1.5, 0)
	add_child(health_bar_container)
	
	health_bar_bg = MeshInstance3D.new()
	health_bar_bg.name = "Background"
	var bg_mesh = PlaneMesh.new()
	bg_mesh.size = Vector2(1.2, 0.2)
	health_bar_bg.mesh = bg_mesh
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.1)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_bg.set_surface_override_material(0, bg_mat)
	health_bar_container.add_child(health_bar_bg)
	
	health_bar_fill = MeshInstance3D.new()
	health_bar_fill.name = "Fill"
	var fill_mesh = PlaneMesh.new()
	fill_mesh.size = Vector2(1.0, 0.15)
	health_bar_fill.mesh = fill_mesh
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.8, 0.2)
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	health_bar_fill.set_surface_override_material(0, fill_mat)
	health_bar_fill.position = Vector3(0, 0, 0.01)
	health_bar_container.add_child(health_bar_fill)

func update_health_bar() -> void:
	if health_bar_fill == null:
		return
	
	var health_percent = float(current_health) / float(max_health)
	
	var new_mesh = PlaneMesh.new()
	new_mesh.size = Vector2(1.0 * health_percent, 0.15)
	health_bar_fill.mesh = new_mesh
	
	var new_color: Color
	if health_percent > 0.6:
		new_color = Color(0.2, 0.8, 0.2)
	elif health_percent > 0.3:
		new_color = Color(0.9, 0.9, 0.2)
	else:
		new_color = Color(0.9, 0.2, 0.2)
	
	var mat = health_bar_fill.get_surface_override_material(0)
	if mat:
		mat.albedo_color = new_color

func show_damage_number(amount: int) -> void:
	var damage_label = Label3D.new()
	damage_label.text = "-" + str(amount)
	damage_label.font_size = 64
	damage_label.modulate = Color(1, 0, 0, 1)
	damage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	damage_label.position = Vector3(0, 2.0, 0)
	add_child(damage_label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", 3.0, 1.0)
	tween.tween_property(damage_label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	damage_label.queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 15.0 * delta
	
	if player == null or not is_instance_valid(player):
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > DETECTION_RANGE:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	elif distance_to_player <= ATTACK_RANGE:
		look_at_player()
		
		if can_attack:
			perform_attack()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	
	else:
		chase_player(delta)
	
	update_attack_cooldown(delta)
	move_and_slide()

func chase_player(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	
	path_update_time += delta
	if path_update_time >= path_update_interval:
		if nav_agent:
			nav_agent.target_position = player.global_position
		path_update_time = 0.0
	
	var direction: Vector3
	
	if nav_agent and not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		direction = (next_pos - global_position).normalized()
		
		if direction.length() < 0.1:
			direction = (player.global_position - global_position).normalized()
			direction.y = 0
	else:
		direction = (player.global_position - global_position).normalized()
		direction.y = 0
	
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	rotate_towards_direction(direction, delta)

func perform_attack() -> void:
	if player == null or not is_instance_valid(player):
		return
	
	is_attacking = true
	can_attack = false
	attack_timer = 0.0
	
	if player.has_method("take_damage"):
		player.take_damage(DAMAGE)
		print("ZOMBIE ATACA! Daño: ", DAMAGE)
	
	set_color(Color(1.0, 0.2, 0.2))
	await get_tree().create_timer(0.2).timeout
	set_color(original_color)
	is_attacking = false

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
	
	print("Zombie herido! Daño: -", amount, " | Vida: ", current_health, "/", max_health)
	
	show_damage_number(amount)
	update_health_bar()
	
	set_color(Color(1.0, 1.0, 1.0))
	await get_tree().create_timer(0.1).timeout
	set_color(original_color)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("☠️ ZOMBIE MUERE")
	
	set_physics_process(false)
	
	if nav_agent:
		nav_agent.avoidance_enabled = false
	
	# Notificar al Game Manager
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm and gm.has_method("zombie_died"):
		gm.zombie_died()
		print("Game Manager notificado")
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	
	if mesh_instance and mesh_instance.get_surface_override_material(0):
		var mat = mesh_instance.get_surface_override_material(0)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	
	await tween.finished
	
	create_blood_particles()
	spawn_coin()
	
	queue_free()

func create_blood_particles() -> void:
	var particles = GPUParticles3D.new()
	particles.name = "BloodParticles"
	particles.position = global_position
	get_tree().get_root().add_child(particles)
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.5
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 90.0
	particle_material.initial_velocity_min = 2.0
	particle_material.initial_velocity_max = 5.0
	particle_material.gravity = Vector3(0, -9.8, 0)
	particle_material.color = Color(0.8, 0.1, 0.1, 1.0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	
	particles.process_material = particle_material
	
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.05
	particle_mesh.height = 0.1
	particles.draw_pass_1 = particle_mesh
	
	particles.amount = 20
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true
	
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func spawn_coin() -> void:
	var coin = Node3D.new()
	coin.name = "Coin"
	coin.position = global_position + Vector3(0, 0.5, 0)
	get_tree().get_root().add_child(coin)
	
	var coin_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.2
	cylinder.height = 0.05
	coin_mesh.mesh = cylinder
	coin_mesh.rotation.x = PI / 2
	
	var coin_mat = StandardMaterial3D.new()
	coin_mat.albedo_color = Color(1.0, 0.84, 0.0)
	coin_mat.metallic = 1.0
	coin_mat.roughness = 0.2
	coin_mesh.material_override = coin_mat
	
	coin.add_child(coin_mesh)
	
	var script = load("res://scripts/Coin.gd")
	if script:
		coin.set_script(script)
	
	var tween = create_tween()
	tween.tween_property(coin, "position:y", coin.position.y + 1.0, 0.3)
	tween.tween_property(coin, "position:y", coin.position.y, 0.3)

func update_attack_cooldown(delta: float) -> void:
	if not can_attack:
		attack_timer += delta
		if attack_timer >= ATTACK_COOLDOWN:
			can_attack = true
			attack_timer = 0.0

func look_at_player() -> void:
	if player == null or not is_instance_valid(player):
		return
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.001:
		rotation.y = atan2(-direction.x, -direction.z)

func rotate_towards_direction(direction: Vector3, delta: float) -> void:
	var target_dir = Vector2(direction.x, direction.z)
	if target_dir.length_squared() > 0.001:
		var target_angle = atan2(-direction.x, -direction.z)
		rotation.y = rotate_toward(rotation.y, target_angle, ROTATION_SPEED * delta)

func set_color(new_color: Color) -> void:
	if mesh_instance == null:
		return
	var mat = mesh_instance.get_surface_override_material(0)
	if mat:
		mat.albedo_color = new_color
	else:
		var new_mat = StandardMaterial3D.new()
		new_mat.albedo_color = new_color
		mesh_instance.set_surface_override_material(0, new_mat)
