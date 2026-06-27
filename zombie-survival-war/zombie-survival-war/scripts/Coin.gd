extends Area3D

# ============================================================
# MONEDA - Sistema de recolección
# ============================================================

@export var coin_value: int = 10
@export var rotation_speed: float = 3.0
@export var collection_distance: float = 2.0

var is_collected: bool = false

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	# Asegurar que tenemos CollisionShape3D
	if not has_node("CollisionShape3D"):
		push_error("Coin: No tiene CollisionShape3D. Añade uno en la escena.")
		return

	# Conectar señal de colisión
	body_entered.connect(_on_body_entered)

	print("Moneda lista en: ", global_position)

# ============================================================
# PROCESS - Gira la moneda
# ============================================================
func _process(delta: float) -> void:
	if is_collected:
		return

	# Girar la moneda sobre sí misma
	rotate_y(delta * rotation_speed)

# ============================================================
# DETECCIÓN DE COLISIÓN
# ============================================================
func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return

	# Verificar que es el jugador
	if not body.is_in_group("Player"):
		return

	# ¡Recoger!
	collect_coin()

# ============================================================
# RECOLECCIÓN
# ============================================================
func collect_coin() -> void:
	if is_collected:
		return

	is_collected = true
	print("💰 MONEDA RECOGIDA: +", coin_value)

	# Notificar al GameManager
	var game_manager = get_game_manager()
	if game_manager and game_manager.has_method("add_coins"):
		game_manager.add_coins(coin_value)
		print("Monedas totales: ", game_manager.get_total_coins())
	else:
		push_warning("No se encontró GameManager para sumar monedas")

	# Animación de desaparición
	disappear()

# ============================================================
# DESAPARICIÓN
# ============================================================
func disappear() -> void:
	# Desactivar colisiones para no detectar más
	set_deferred("monitoring", false)

	# Obtener el mesh hijo para animar su material
	var mesh = get_node_or_null("MeshInstance3D")
	var mesh_tween_target = mesh if mesh != null else self

	# Animación: escalar a cero y desaparecer
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2)

	# Si tenemos mesh, animar su transparencia
	if mesh and mesh.get_surface_override_material(0):
		var mat = mesh.get_surface_override_material(0)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)

	await tween.finished

	if is_instance_valid(self):
		queue_free()

# ============================================================
# BUSCAR GAME MANAGER
# ============================================================
func get_game_manager() -> Node:
	# Método 1: Autoload (la forma más confiable en Godot)
	var autoload = get_node_or_null("/root/GameManager")
	if autoload != null and is_instance_valid(autoload):
		return autoload

	# Método 2: Por grupo
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm != null and is_instance_valid(gm):
		return gm

	# Método 3: Buscar en la escena principal
	var main = get_tree().get_root().find_child("Main", true, false)
	if main:
		for child in main.get_children():
			if child.name == "GameManager":
				return child

	return null
