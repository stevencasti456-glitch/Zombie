extends Control

# ============================================================
# UI DEL JUEGO - FASE 7 + 8
# ============================================================

@onready var health_bar: ProgressBar = $HealthBar2
@onready var zombies_label: Label = $ZombiesLabel2
@onready var wave_label: Label = $WaveLabel2
@onready var coins_label: Label = $CoinsLabel    # ← NUEVO: label de monedas

var game_manager: Node = null
var signals_connected: bool = false

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	# Buscar GameManager
	game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null:
		game_manager = get_tree().get_first_node_in_group("GameManager")

	# Conectar señales del GameManager (solo una vez)
	if game_manager and not signals_connected:
		if game_manager.zombie_killed.is_connected(_on_zombie_killed) == false:
			game_manager.zombie_killed.connect(_on_zombie_killed)
		if game_manager.wave_started.is_connected(_on_wave_started) == false:
			game_manager.wave_started.connect(_on_wave_started)
		if game_manager.wave_completed.is_connected(_on_wave_completed) == false:
			game_manager.wave_completed.connect(_on_wave_completed)
		if game_manager.coins_changed.is_connected(_on_coins_changed) == false:
			game_manager.coins_changed.connect(_on_coins_changed)
		signals_connected = true
		print("UI conectada al GameManager")
	else:
		push_warning("No se encontro GameManager para la UI")

	# Valores iniciales
	update_health_bar(100, 100)
	update_zombies_label(0)
	update_wave_label(1)
	update_coins_label(0)    # ← NUEVO

# ============================================================
# ACTUALIZAR BARRA DE VIDA
# ============================================================
func update_health_bar(current: int, maximum: int) -> void:
	if health_bar == null:
		return

	health_bar.max_value = maximum
	health_bar.value = current

	var health_percent = float(current) / float(maximum)

	var fill_style = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style == null:
		fill_style = StyleBoxFlat.new()
		health_bar.add_theme_stylebox_override("fill", fill_style)

	if health_percent > 0.6:
		fill_style.bg_color = Color(0.2, 0.8, 0.2)
	elif health_percent > 0.3:
		fill_style.bg_color = Color(0.9, 0.9, 0.2)
	else:
		fill_style.bg_color = Color(0.9, 0.2, 0.2)

# ============================================================
# ACTUALIZAR CONTADOR DE ZOMBIES
# ============================================================
func update_zombies_label(count: int) -> void:
	if zombies_label == null:
		return
	zombies_label.text = "Zombies: " + str(count)

# ============================================================
# ACTUALIZAR NUMERO DE OLEADA
# ============================================================
func update_wave_label(wave: int) -> void:
	if wave_label == null:
		return
	wave_label.text = "Oleada: " + str(wave)

# ============================================================
# ACTUALIZAR MONEDAS  ← NUEVO
# ============================================================
func update_coins_label(amount: int) -> void:
	if coins_label == null:
		return
	coins_label.text = "Monedas: " + str(amount)

# ============================================================
# SEÑALES DEL GAME MANAGER
# ============================================================
func _on_zombie_killed(count: int) -> void:
	update_zombies_label(count)

func _on_wave_started(wave_number: int, _zombie_count: int) -> void:
	update_wave_label(wave_number)

func _on_wave_completed(_wave_number: int) -> void:
	print("Oleada completada!")

func _on_coins_changed(amount: int) -> void:    # ← AHORA SÍ FUNCIONA
	update_coins_label(amount)

# ============================================================
# ACTUALIZACION MANUAL (fallback)
# ============================================================
func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("get_health"):
		var current = player.get_health()
		var maximum = player.max_health
		update_health_bar(current, maximum)
