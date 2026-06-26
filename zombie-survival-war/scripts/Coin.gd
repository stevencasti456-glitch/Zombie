extends Node3D

@export var coin_value: int = 10
var is_collected: bool = false

func _ready() -> void:
	print("MONEDA _ready() ejecutado!")

func _process(delta: float) -> void:
	# GIRAR la moneda
	rotate_y(delta * 3.0)
	
	if is_collected:
		return
	
	# Buscar jugador
	var player = get_tree().get_first_node_in_group("Player")
	if player == null:
		player = get_tree().get_root().find_child("Player", true, false)
	
	if player == null or not is_instance_valid(player):
		return
	
	# Calcular distancia
	var distance = global_position.distance_to(player.global_position)
	
	# DEBUG cada 2 segundos
	if Engine.get_process_frames() % 120 == 0:
		print("MONEDA: Distancia al jugador: ", distance)
	
	# Recoger si está cerca
	if distance < 1.5:
		collect_coin()

func collect_coin() -> void:
	if is_collected:
		return
	
	is_collected = true
	print("MONEDA RECOGIDA: +", coin_value)
	
	# Buscar Game Manager
	var game_manager = find_game_manager()
	
	if game_manager and game_manager.has_method("add_coins"):
		game_manager.add_coins(coin_value)
		print("Monedas totales: ", game_manager.get_total_coins())
	else:
		print("NO HAY GAME MANAGER - Moneda recogida sin sumar")
	
	# ✅ CORREGIDO: Desaparecer inmediatamente con tween más simple
	disappear()

func disappear() -> void:
	# Hacer invisible y pequeño rápidamente
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.15)
	tween.tween_property(self, "visible", false, 0.0)
	
	# Esperar un poco y destruir
	await get_tree().create_timer(0.2).timeout
	
	if is_instance_valid(self):
		print("MONEDA DESTRUIDA")
		queue_free()

func find_game_manager() -> Node:
	# Método 1: Por grupo
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm != null and is_instance_valid(gm):
		return gm
	
	# Método 2: Por nombre
	gm = get_tree().get_root().find_child("GameManager", true, false)
	if gm != null and is_instance_valid(gm):
		return gm
	
	# Método 3: Buscar en Main
	var main = get_tree().get_root().find_child("Main", true, false)
	if main:
		for child in main.get_children():
			if child.name == "GameManager":
				return child
	
	return null
