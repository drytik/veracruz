class_name ConstructionArea
extends Area2D

signal area_clicked(area: ConstructionArea)

enum TYPE {
	x2x1, 
	x2x2,
	x3x2, 
	WALL, 
	WORKSHOP,
	PORT
}

@export_enum("x2x1", "x2x2", "x3x2", "WALL", "WORKSHOP", "PORT") var area_type : int
@export var center_position : Vector2 = Vector2.ZERO
@export var is_occupied : bool = false

# Metadata para extractores (WorldMap)
@export var is_extractor_zone : bool = false
@export_enum("lumbermill", "quarry", "plantation") var extractor_type : String = "lumbermill"  # Lista desplegable con valor por defecto
@export var available_resources : Array[String] = []  # ["wood"] o ["stone", "silver"]

var highlight_shape: Node2D
var zone_id : String = ""  # ID único para save/load

func _ready() -> void:
	# Configurar collision layers
	collision_layer = 1  # Layer 1 para áreas
	collision_mask = 1   # Mask 1
	
	# Añadir a grupos según tipo
	if is_extractor_zone:
		add_to_group("world_extractor_zones")
		zone_id = extractor_type + "_" + str(get_instance_id())
	else:
		add_to_group("city_construction_areas")
	
	# NO calcular center_position aquí, lo haremos dinámicamente
	_create_highlight()
	
	# Hacer clickeable
	input_pickable = true
	
	# Conectar señales
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func get_global_center() -> Vector2:
	var collision_shape = get_node("CollisionShape2D")
	if collision_shape:
		# Obtener la posición global del CollisionShape2D
		var center = collision_shape.global_position
		
		# Compensar por la escala del CitySprite (0.5, 0.5)
		# El offset visual puede necesitar ajuste manual
		var offset_correction = Vector2(0, -50)  # Ajusta este valor según necesites
		
		return center + offset_correction
	return global_position

func _create_highlight() -> void:
	# Esperar si el nodo no está listo
	await get_tree().process_frame
	
	# Duplicar el CollisionShape2D existente
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		print("Warning: No CollisionShape2D found for highlight")
		return
		
	highlight_shape = collision_shape.duplicate()
	
	# Convertir a visual con Polygon2D
	var polygon = Polygon2D.new()
	polygon.color = Color(1.0, 1.0, 1.0, 0.3)
	# Si es RectangleShape2D, crear el polígono
	if collision_shape.shape is RectangleShape2D:
		var size = collision_shape.shape.size
		var points = PackedVector2Array([
			Vector2(-size.x/2, -size.y/2),
			Vector2(size.x/2, -size.y/2), 
			Vector2(size.x/2, size.y/2),
			Vector2(-size.x/2, size.y/2)
		])
		polygon.polygon = points
		polygon.z_index = 1
	
	# Limpiar el highlight duplicado y añadir el polígono
	for child in highlight_shape.get_children():
		child.queue_free()
	
	highlight_shape.add_child(polygon)
	highlight_shape.visible = false
	highlight_shape.z_index = 1
	add_child(highlight_shape)

func show_highlight() -> void:
	if not is_occupied and highlight_shape:
		highlight_shape.visible = true

func hide_highlight() -> void:
	if highlight_shape:
		highlight_shape.visible = false

func _on_mouse_entered() -> void:
	if is_extractor_zone and not is_occupied:
		modulate = Color(1.1, 1.1, 1.1)  # Iluminar un poco al hover

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Consumir el evento para evitar duplicados
			get_viewport().set_input_as_handled()
			
			if is_extractor_zone:
				# Abrir popup del extractor
				_open_extractor_popup()
			else:
				emit_signal("area_clicked", self)

func _open_extractor_popup() -> void:
	# Obtener nivel actual de la zona (por ahora 0, luego lo sacaremos de progression)
	var level = 0
	
	# Para pruebas, si no tiene tipo asignado, usar lumbermill
	if extractor_type == "":
		extractor_type = "lumbermill"
	
	PopupManager.ref.show_extractor_popup(zone_id, extractor_type, level)
