extends Node3D

@onready var terrain_mesh_instance: MeshInstance3D = $Terrain/MeshInstance3D
@onready var terrain_collision: CollisionShape3D = $Terrain/CollisionShape3D
@onready var rocks_container: Node3D = $RocksContainer
@onready var vegetation_container: Node3D = $VegetationContainer

const ISLAND_RADIUS: float = 150.0
const ROCK_COUNT: int = 25
const VEGETATION_COUNT: int = 500

var placed_items: Array = []

func _ready() -> void:
	global_position = Vector3.ZERO
	if has_node("Terrain"):
		$Terrain.position = Vector3.ZERO

	generate_island_mesh()
	generate_decorations()
	
	call_deferred("bake_navigation_mesh")

func get_terrain_height(x: float, z: float) -> float:
	var dist = Vector2(x, z).length()
	var height = 12.0 + (sin(x * 0.05) * cos(z * 0.05) * 6.0) + (sin(x * 0.02) * 10.0)
	if dist > ISLAND_RADIUS - 30.0:
		height -= (dist - (ISLAND_RADIUS - 30.0)) * 1.5
	return height

func generate_island_mesh() -> void:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(ISLAND_RADIUS * 2, ISLAND_RADIUS * 2)
	plane_mesh.subdivide_width = 60
	plane_mesh.subdivide_depth = 60
	
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)
	var array_mesh = surface_tool.commit()
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		vertex.y = get_terrain_height(vertex.x, vertex.z)
		mdt.set_vertex(i, vertex)
	
	array_mesh.clear_surfaces()
	mdt.commit_to_surface(array_mesh)
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_mesh, 0)
	surface_tool.generate_normals()
	var final_mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.4, 0.1)
	material.roughness = 0.9
	
	terrain_mesh_instance.mesh = final_mesh
	terrain_mesh_instance.set_surface_override_material(0, material)
	
	var trimesh_shape = final_mesh.create_trimesh_shape()
	if trimesh_shape:
		terrain_collision.shape = trimesh_shape

func bake_navigation_mesh() -> void:
	var nav_region = get_parent() as NavigationRegion3D
	if not nav_region:
		push_error("No se encontro NavigationRegion3D como padre de Island")
		return
	
	var nav_mesh = NavigationMesh.new()
	
	# ✅ CORREGIDO: Buscar geometría en grupos y sus hijos
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	
	# ✅ CORREGIDO: Usar colliders estáticos como geometría
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	
	# Nombre del grupo que contiene el terreno
	nav_mesh.geometry_source_group_name = "navigation"
	
	# Configurar celdas
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.5
	
	# Configurar agente (tamaño del zombie)
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.5
	nav_mesh.agent_max_slope = 45.0
	
	# Asignar y hornear
	nav_region.navigation_mesh = nav_mesh
	nav_region.bake_navigation_mesh()
	
	print("NavMesh horneado correctamente")

func check_space_and_place(x: float, z: float, radius: float) -> bool:
	for item in placed_items:
		var dist = sqrt(pow(x - item.x, 2) + pow(z - item.z, 2))
		if dist < (radius + item.r):
			return false
	if sqrt(x * x + z * z) < 15.0:
		return false
	placed_items.append({"x": x, "z": z, "r": radius})
	return true

func generate_decorations() -> void:
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.3, 0.3, 0.3)
	
	var i = 0
	while i < ROCK_COUNT:
		var x = randf_range(-100.0, 100.0)
		var z = randf_range(-100.0, 100.0)
		var scale_factor = randf_range(1.5, 4.0)
		
		if check_space_and_place(x, z, scale_factor * 1.5):
			var static_body = StaticBody3D.new()
			var collision = CollisionShape3D.new()
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = scale_factor
			collision.shape = sphere_shape
			
			var mesh_instance = MeshInstance3D.new()
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = scale_factor
			sphere_mesh.height = scale_factor * 2.0
			mesh_instance.mesh = sphere_mesh
			mesh_instance.set_surface_override_material(0, rock_mat)
			
			static_body.add_child(mesh_instance)
			static_body.add_child(collision)
			rocks_container.add_child(static_body)
			
			var terrain_y = get_terrain_height(x, z)
			static_body.transform.origin = Vector3(x, terrain_y + scale_factor * 0.3, z)
			i += 1
	
	var multimesh_instance = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.5, 1.0)
	
	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.2, 0.8, 0.2)
	grass_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	mm.mesh = quad_mesh
	mm.instance_count = VEGETATION_COUNT
	multimesh_instance.multimesh = mm
	multimesh_instance.material_override = grass_mat
	vegetation_container.add_child(multimesh_instance)
	
	var grass_placed = 0
	while grass_placed < VEGETATION_COUNT:
		var x = randf_range(-120.0, 120.0)
		var z = randf_range(-120.0, 120.0)
		
		var dist_from_center = sqrt(x * x + z * z)
		if dist_from_center < ISLAND_RADIUS - 10.0:
			var terrain_y = get_terrain_height(x, z)
			
			var t = Transform3D()
			var random_height = randf_range(0.6, 1.3)
			var random_rotation = randf_range(0, PI * 2)
			
			t = t.scaled(Vector3(1.0, random_height, 1.0))
			t = t.rotated(Vector3.UP, random_rotation)
			t.origin = Vector3(x, terrain_y + 0.25, z)
			
			mm.set_instance_transform(grass_placed, t)
			grass_placed += 1
