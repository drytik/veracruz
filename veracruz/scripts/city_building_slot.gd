class_name CityBuildingSlot
extends Area2D

signal slot_clicked(slot: CityBuildingSlot)

enum SlotSize {
	SMALL_2x1,
	MEDIUM_2x2,
	LARGE_3x2,
	WALL,
	WORKSHOP,
	PORT
}

@export var slot_size : SlotSize = SlotSize.MEDIUM_2x2
@export var is_occupied : bool = false
@export var allowed_building_types : Array[String] = []

var highlight_polygon : Polygon2D
var current_building : Node2D = null
var slot_id : String = ""
var current_building_id : String = ""
var current_building_visual : Node2D
var slot_global_position : Vector2  # Almacenar la posición global real

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0  # No necesita detectar otros
	
	slot_id = name + "_" + str(get_instance_id())
	
	add_to_group("city_building_slots")
	
	# Calcular y almacenar la posición global real
	_update_global_position()
	
	# Crear highlight después de un frame
	call_deferred("_create_highlight")
	
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	call_deferred("_initialize_slot")

func _update_global_position() -> void:
	# Obtener la posición global real considerando todas las transformaciones
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		slot_global_position = collision_shape.global_position
	else:
		slot_global_position = global_position

func _initialize_slot() -> void:
	_check_existing_building()
	
	if BuildingSystem.ref:
		if not BuildingSystem.ref.building_constructed.is_connected(_on_building_constructed):
			BuildingSystem.ref.building_constructed.connect(_on_building_constructed)
		if not BuildingSystem.ref.building_demolished.is_connected(_on_building_demolished):
			BuildingSystem.ref.building_demolished.connect(_on_building_demolished)

func _check_existing_building() -> void:
	if BuildingSystem.ref:
		var buildings = BuildingSystem.ref.get_buildings_at_slot(slot_id)
		if buildings.size() > 0:
			is_occupied = true
			current_building_id = buildings[0].instance_id
			_create_building_visual(buildings[0])

func _create_building_visual(building: BuildingInstance) -> void:
	if current_building_visual:
		current_building_visual.queue_free()
		current_building_visual = null
	
	current_building_visual = Node2D.new()
	current_building_visual.name = "BuildingVisual"
	current_building_visual.position = Vector2.ZERO  # Posición local
	
	var template = building.get_template()
	if template.is_empty():
		return
	
	var texture_path = template.get("texture_path", "")
	
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(texture_path)
		sprite.scale = Vector2(0.25, 0.25)  # Escala más pequeña para los edificios
		current_building_visual.add_child(sprite)
	else:
		var placeholder = ColorRect.new()
		placeholder.size = Vector2(60, 60)
		placeholder.position = Vector2(-30, -30)
		placeholder.color = Color(0.4, 0.4, 0.6, 0.8)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_building_visual.add_child(placeholder)
		
		var label = Label.new()
		label.text = template.get("name", "Building")
		label.position = Vector2(-25, -5)
		label.add_theme_font_size_override("font_size", 10)
		current_building_visual.add_child(label)
	
	add_child(current_building_visual)

func _create_highlight() -> void:
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		return
	
	highlight_polygon = Polygon2D.new()
	highlight_polygon.name = "HighlightPolygon"
	highlight_polygon.color = Color(0.3, 0.8, 0.3, 0.4)
	highlight_polygon.z_index = -1
	
	if collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		var size = rect_shape.size * collision_shape.scale.abs()
		
		# Crear puntos del rectángulo
		var points = PackedVector2Array([
			Vector2(-size.x/2, -size.y/2),
			Vector2(size.x/2, -size.y/2),
			Vector2(size.x/2, size.y/2),
			Vector2(-size.x/2, size.y/2)
		])
		
		highlight_polygon.polygon = points
		highlight_polygon.position = collision_shape.position
		highlight_polygon.rotation = collision_shape.rotation
		highlight_polygon.scale = Vector2(1, 1)  # No aplicar escala extra
	
	highlight_polygon.visible = false
	add_child(highlight_polygon)

func show_highlight() -> void:
	if not is_occupied and highlight_polygon:
		highlight_polygon.visible = true
		highlight_polygon.color = Color(0.3, 0.8, 0.3, 0.4)

func hide_highlight() -> void:
	if highlight_polygon:
		highlight_polygon.visible = false

func show_invalid_highlight() -> void:
	if highlight_polygon:
		highlight_polygon.visible = true
		highlight_polygon.color = Color(0.8, 0.3, 0.3, 0.4)

func get_global_center() -> Vector2:
	_update_global_position()  # Actualizar por si acaso
	return slot_global_position

func can_place_building(building_type: String) -> bool:
	if is_occupied:
		return false
	
	# Verificar restricciones especiales
	if slot_size == SlotSize.PORT:
		return building_type == "port"
	elif slot_size == SlotSize.WALL:
		return building_type == "wall"
	
	# Para otros slots, verificar si el edificio es especial
	if building_type in ["port", "wall"]:
		return false
	
	# Si no hay restricciones específicas, permitir
	return allowed_building_types.is_empty() or building_type in allowed_building_types

func place_building(building_type: String) -> bool:
	if not can_place_building(building_type):
		return false
	
	is_occupied = true
	hide_highlight()
	
	return true

func remove_building() -> void:
	is_occupied = false
	current_building_id = ""
	if current_building_visual:
		current_building_visual.queue_free()
		current_building_visual = null

func _on_building_constructed(building: BuildingInstance) -> void:
	if building.slot_id == slot_id:
		is_occupied = true
		current_building_id = building.instance_id
		_create_building_visual(building)
		hide_highlight()

func _on_building_demolished(building: BuildingInstance) -> void:
	if building.instance_id == current_building_id:
		remove_building()

func _on_mouse_entered() -> void:
	if not is_occupied:
		modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_occupied and BuildingSystem.ref:
				var building = BuildingSystem.ref.get_building_by_id(current_building_id)
				if building and PopupManager.ref:
					PopupManager.ref.show_building_popup(building)
			else:
				emit_signal("slot_clicked", self)

func _exit_tree() -> void:
	if BuildingSystem.ref:
		if BuildingSystem.ref.building_constructed.is_connected(_on_building_constructed):
			BuildingSystem.ref.building_constructed.disconnect(_on_building_constructed)
		if BuildingSystem.ref.building_demolished.is_connected(_on_building_demolished):
			BuildingSystem.ref.building_demolished.disconnect(_on_building_demolished)
