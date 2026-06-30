extends CanvasLayer

# ============================================================
# HUD MODERNO - FASE 2.7
# ============================================================

# Referencias a nodos del HUD
var health_bar: ProgressBar
var health_icon: Control
var zombies_icon: Control
var wave_icon: Control
var nucleo_icon: Control
var crosshair: Control

# Datos del juego
var current_health: int = 100
var max_health: int = 100
var current_zombies: int = 0
var current_wave: int = 1
var current_nucleos: int = 0
var target_nucleos: int = 0  # Para animación

# Animación de monedas
var nucleo_animation_active: bool = false
var nucleo_animation_speed: float = 10.0

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	# Crear elementos del HUD
	create_health_bar()
	create_counters()
	create_crosshair()
	
	# Posicionar elementos
	position_elements()
	
	# Conectar señales del GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.coins_changed.connect(_on_coins_changed)
		gm.wave_started.connect(_on_wave_started)

# ============================================================
# CREAR BARRA DE VIDA
# ============================================================
func create_health_bar() -> void:
	# Contenedor principal
	var container = Control.new()
	container.name = "HealthContainer"
	container.custom_minimum_size = Vector2(300, 40)  # ← Más grande
	add_child(container)
	
	# Icono de corazón
	health_icon = create_heart_icon()
	health_icon.name = "HealthIcon"
	health_icon.position = Vector2(0, 0)
	container.add_child(health_icon)
	
	# Barra de vida estilizada
	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.custom_minimum_size = Vector2(260, 30)  # ← Más ancha y alta
	health_bar.position = Vector2(40, 5)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false

func create_heart_icon() -> Control:
	var icon = Control.new()
	icon.custom_minimum_size = Vector2(30, 30)
	
	# Corazón dibujado con Polygon2D
	var heart = Polygon2D.new()
	var points = PackedVector2Array([
		Vector2(15, 8),
		Vector2(22, 3),
		Vector2(27, 8),
		Vector2(27, 15),
		Vector2(15, 27),
		Vector2(3, 15),
		Vector2(3, 8),
		Vector2(8, 3)
	])
	heart.polygon = points
	heart.color = Color(0.9, 0.1, 0.1)
	icon.add_child(heart)
	
	return icon

# ============================================================
# CREAR CONTADORES (ZOMBIES, OLEADA, NÚCLEOS)
# ============================================================
func create_counters() -> void:
	# Contador de Zombies
	zombies_icon = create_counter_icon("skull")
	zombies_icon.name = "ZombiesCounter"
	add_child(zombies_icon)
	
	# Contador de Oleada
	wave_icon = create_counter_icon("shield")
	wave_icon.name = "WaveCounter"
	add_child(wave_icon)
	
	# Contador de Núcleos
	nucleo_icon = create_nucleo_counter()
	nucleo_icon.name = "NucleoCounter"
	add_child(nucleo_icon)

func create_counter_icon(type: String) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(80, 40)
	
	# Icono
	var icon = Control.new()
	icon.custom_minimum_size = Vector2(30, 30)
	icon.position = Vector2(0, 5)
	
	if type == "skull":
		# Calavera simple
		var skull = Polygon2D.new()
		var points = PackedVector2Array([
			Vector2(15, 5), Vector2(22, 8), Vector2(25, 15),
			Vector2(22, 22), Vector2(15, 25), Vector2(8, 22),
			Vector2(5, 15), Vector2(8, 8)
		])
		skull.polygon = points
		skull.color = Color(0.7, 0.7, 0.7)
		icon.add_child(skull)
		
		# Ojos
		var eye_left = Polygon2D.new()
		eye_left.polygon = PackedVector2Array([Vector2(10, 12), Vector2(13, 12), Vector2(13, 15), Vector2(10, 15)])
		eye_left.color = Color(0.1, 0.1, 0.1)
		icon.add_child(eye_left)
		
		var eye_right = Polygon2D.new()
		eye_right.polygon = PackedVector2Array([Vector2(17, 12), Vector2(20, 12), Vector2(20, 15), Vector2(17, 15)])
		eye_right.color = Color(0.1, 0.1, 0.1)
		icon.add_child(eye_right)
	
	elif type == "shield":
		# Escudo simple
		var shield = Polygon2D.new()
		var points = PackedVector2Array([
			Vector2(15, 3), Vector2(25, 8), Vector2(25, 18),
			Vector2(15, 27), Vector2(5, 18), Vector2(5, 8)
		])
		shield.polygon = points
		shield.color = Color(0.2, 0.5, 0.8)
		icon.add_child(shield)
	
	container.add_child(icon)
	
	# Número
	var label = Label.new()
	label.name = "NumberLabel"
	label.position = Vector2(35, 5)
	label.custom_minimum_size = Vector2(45, 30)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.text = "0"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	return container

func create_nucleo_counter() -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(120, 40)
	
	# Icono del Núcleo
	var icon = create_nucleo_icon()
	icon.position = Vector2(0, 0)
	container.add_child(icon)
	
	# Número animado
	var label = Label.new()
	label.name = "NucleoLabel"
	label.position = Vector2(40, 5)
	label.custom_minimum_size = Vector2(80, 30)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	label.text = "0"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	return container

func create_nucleo_icon() -> Control:
	var icon = Control.new()
	icon.custom_minimum_size = Vector2(35, 35)
	
	# Borde plateado (círculo)
	var outer_ring = Polygon2D.new()
	var outer_points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		outer_points.append(Vector2(17.5 + cos(angle) * 16, 17.5 + sin(angle) * 16))
	outer_ring.polygon = outer_points
	outer_ring.color = Color(0.75, 0.75, 0.8)
	icon.add_child(outer_ring)
	
	# Brillo interno
	var glow = Polygon2D.new()
	var glow_points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		glow_points.append(Vector2(17.5 + cos(angle) * 13, 17.5 + sin(angle) * 13))
	glow.polygon = glow_points
	glow.color = Color(1, 0.9, 0.3, 0.4)
	icon.add_child(glow)
	
	# Hexágono central
	var hexagon = Polygon2D.new()
	var hex_points = PackedVector2Array()
	for i in range(6):
		var angle = (i / 6.0) * TAU - PI / 6
		hex_points.append(Vector2(17.5 + cos(angle) * 10, 17.5 + sin(angle) * 10))
	hexagon.polygon = hex_points
	hexagon.color = Color(1, 0.6, 0.0)
	icon.add_child(hexagon)
	
	# Núcleo brillante
	var core = Polygon2D.new()
	var core_points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		core_points.append(Vector2(17.5 + cos(angle) * 5, 17.5 + sin(angle) * 5))
	core.polygon = core_points
	core.color = Color(1, 0.95, 0.5)
	icon.add_child(core)
	
	return icon

# ============================================================
# CROSSHAIR MINIMALISTA
# ============================================================
func create_crosshair() -> Control:
	var container = Control.new()
	container.name = "Crosshair"
	container.custom_minimum_size = Vector2(20, 20)
	container.z_index = 100  # ← Por encima de todo
	container.position = Vector2(get_viewport().size.x / 2 - 10, get_viewport().size.y / 2 - 10)
	
	# Punto central (más visible)
	var dot = Polygon2D.new()
	var dot_points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		dot_points.append(Vector2(10 + cos(angle) * 3, 10 + sin(angle) * 3))
	dot.polygon = dot_points
	dot.color = Color(1, 1, 1, 0.95)
	container.add_child(dot)
	
	# Círculo sutil
	var circle = Polygon2D.new()
	var circle_points = PackedVector2Array()
	for i in range(32):
		var angle = (i / 32.0) * TAU
		circle_points.append(Vector2(10 + cos(angle) * 8, 10 + sin(angle) * 8))
	circle.polygon = circle_points
	circle.color = Color(1, 1, 1, 0.3)
	container.add_child(circle)
	
	return container

# ============================================================
# POSICIONAR ELEMENTOS
# ============================================================
func position_elements() -> void:
	var viewport_size = get_viewport().size
	var center_x = viewport_size.x / 2
	var bottom_y = viewport_size.y
	
	# Barra de vida: abajo centrada, más grande
	if has_node("HealthContainer"):
		$HealthContainer.position = Vector2(center_x - 150, bottom_y - 80)
	
	# Contadores: arriba distribuidos
	if zombies_icon:
		zombies_icon.position = Vector2(center_x - 200, 20)
	
	if wave_icon:
		wave_icon.position = Vector2(center_x - 50, 20)
	
	if nucleo_icon:
		nucleo_icon.position = Vector2(center_x + 100, 20)
	
	# Crosshair: centro exacto
	if crosshair:
		crosshair.position = Vector2(center_x - 10, viewport_size.y / 2 - 10)

# ============================================================
# ACTUALIZAR DATOS
# ============================================================
func update_health(health: int, max_hp: int) -> void:
	current_health = health
	max_health = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = health
		
		# Cambiar color según la vida
		var fill_style = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			var health_percent = float(health) / max_hp
			if health_percent > 0.6:
				fill_style.bg_color = Color(0.2, 0.8, 0.2)  # Verde
			elif health_percent > 0.3:
				fill_style.bg_color = Color(0.9, 0.8, 0.1)  # Amarillo
			else:
				fill_style.bg_color = Color(0.9, 0.1, 0.1)  # Rojo

func update_zombies(count: int) -> void:
	current_zombies = count
	if zombies_icon and zombies_icon.has_node("NumberLabel"):
		zombies_icon.get_node("NumberLabel").text = str(count)

func update_wave(wave: int) -> void:
	current_wave = wave
	if wave_icon and wave_icon.has_node("NumberLabel"):
		wave_icon.get_node("NumberLabel").text = str(wave)

func update_nucleos(amount: int) -> void:
	target_nucleos = amount
	if not nucleo_animation_active:
		nucleo_animation_active = true

# ============================================================
# ANIMACIÓN DE MONEDAS
# ============================================================
func _process(delta: float) -> void:
	# Actualizar posiciones en tiempo real (para PC y móvil)
	position_elements()
	if nucleo_animation_active and nucleo_icon:
		var label = nucleo_icon.get_node("NucleoLabel")
		if label:
			var diff = target_nucleos - current_nucleos
			if abs(diff) < 1:
				current_nucleos = target_nucleos
				label.text = str(current_nucleos)
				nucleo_animation_active = false
			else:
				current_nucleos += diff * nucleo_animation_speed * delta
				label.text = str(int(current_nucleos))

# ============================================================
# SEÑALES DEL GAMEMANAGER
# ============================================================
func _on_coins_changed(new_amount: int) -> void:
	update_nucleos(new_amount)

func _on_wave_started(wave_number: int) -> void:
	update_wave(wave_number)

# ============================================================
# REDIMENSIONAR (para diferentes resoluciones)
# ============================================================
func _on_viewport_size_changed() -> void:
	position_elements()
	if crosshair:
		crosshair.position = Vector2(get_viewport().size.x / 2 - 10, get_viewport().size.y / 2 - 10)
