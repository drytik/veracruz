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

var highlight_shape : Node2D
var current_building : Node2D = null
var slot_id : String = ""
var current_building_id : String = ""
var current_building_visual : Node2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	
	slot_id = "city_slot_" + str(get_instance_id())
	
	add_to_group("city_building_slots")
	
	_create_highlight()
	
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Diferir la verificación de edificios existentes para asegurar que los sistemas estén listos
	call_deferred("_initialize_slot")

func _initialize_slot() -> void:
	_check_existing_building()
	
	if BuildingSystem.ref:
		# Conectar señales solo si no están conectadas
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
	# Limpiar visual anterior si existe
	if current_building_visual:
		current_building_visual.queue_free()
		current_building_visual = null
	
	current_building_visual = Node2D.new()
	current_building_visual.name = "BuildingVisual"
	
	var template = building.get_template()
	if template.is_empty():
		push_error("No template found for building type: " + building.building_type)
		return
	
	var texture_path = template.get("texture_path", "")
	
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(texture_path)
		sprite.scale = Vector2(0.5, 0.5)
		current_building_visual.add_child(sprite)
	else:
		# Crear placeholder visual
		var placeholder = ColorRect.new()
		placeholder.size = Vector2(80, 80)
		placeholder.position = Vector2(-40, -40)
		placeholder.color = Color(0.4, 0.4, 0.6, 0.8)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_building_visual.add_child(placeholder)
		
		var label = Label.new()
		label.text = template.get("name", "Building")
		label.position = Vector2(-30, -5)
		current_building_visual.add_child(label)
	
	add_child(current_building_visual)

func _create_highlight() -> void:
	await get_tree().process_frame
	
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		push_warning("No CollisionShape2D found for highlight in slot: " + slot_id)
		return
		
	highlight_shape = collision_shape.duplicate()
	
	var polygon = Polygon2D.new()
	polygon.color = Color(0.3, 0.8, 0.3, 0.3)
	
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
	
	# Limpiar children del duplicado
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

func get_global_center() -> Vector2:
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		return collision_shape.global_position
	return global_position

func can_place_building(building_type: String) -> bool:
	if is_occupied:
		return false
	
	# Si no hay restricciones, permitir cualquier edificio
	if allowed_building_types.is_empty():
		return true
	
	return building_type in allowed_building_types

func place_building(building: Node2D, building_type: String) -> bool:
	if not can_place_building(building_type):
		return false
	
	current_building = building
	is_occupied = true
	hide_highlight()
	
	set_meta("building_type", building_type)
	set_meta("building_node", building)
	
	return true

func remove_building() -> void:
	if current_building:
		current_building.queue_free()
		current_building = null
	
	is_occupied = false
	
	# Limpiar metadatos de forma segura
	if has_meta("building_type"):
		remove_meta("building_type")
	if has_meta("building_node"):
		remove_meta("building_node")

func _on_building_constructed(building: BuildingInstance) -> void:
	if building.slot_id == slot_id:
		is_occupied = true
		current_building_id = building.instance_id
		_create_building_visual(building)
		hide_highlight()

func _on_building_demolished(building: BuildingInstance) -> void:
	if building.instance_id == current_building_id:
		is_occupied = false
		current_building_id = ""
		if current_building_visual:
			current_building_visual.queue_free()
			current_building_visual = null

func _on_mouse_entered() -> void:
	if not is_occupied:
		modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			
			if is_occupied and BuildingSystem.ref:
				var building = BuildingSystem.ref.get_building_by_id(current_building_id)
				if building and PopupManager.ref:
					PopupManager.ref.show_building_popup(building)
			else:
				emit_signal("slot_clicked", self)

func _exit_tree() -> void:
	# Desconectar señales al salir para evitar errores
	if BuildingSystem.ref:
		if BuildingSystem.ref.building_constructed.is_connected(_on_building_constructed):
			BuildingSystem.ref.building_constructed.disconnect(_on_building_constructed)
		if BuildingSystem.ref.building_demolished.is_connected(_on_building_demolished):
			BuildingSystem.ref.building_demolished.disconnect(_on_building_demolished)
