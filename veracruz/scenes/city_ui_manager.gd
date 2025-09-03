extends CanvasLayer

@onready var tooltip = $TooltipPanel
@onready var button1 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button
@onready var button2 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button2
@onready var city_scene: Node2D = $".."

signal building_selected

var buildings: Dictionary = DataBuilding.BUILDINGS  # Usar los datos de DataBuilding
var construction_areas: Array = []

## BUILDING STATE MACHINE

# Construction States
enum BuildingState {
	NORMAL, 
	BUILDING
}

# State variables 
var current_state: BuildingState = BuildingState.NORMAL
var selected_building_id: String = ""
var building_preview: Node2D = null
var current_hover_area: CityBuildingSlot = null  # CAMBIADO: Era ConstructionArea
var snap_distance_threshold: float = 150.0
var is_snapped: bool = false

func _ready() -> void:
	_toggle_menu(0)
	visible = false
	tooltip.visible = false
	
	var building_ids_menu1: Array = ["port", "tavern", "lighthouse", "wall", "palace", "church", "warehouse", "hospital"]
	var building_ids_menu2: Array = ["cityhall", "market", "weaving", "carpentry", "forge", "distillery", "mill"]
	
	# Nota: Los IDs ahora deben coincidir con las keys en DataBuilding.BUILDINGS
	# Cambié de "Port" a "port", "Tabern" a "tavern", etc.
	
	for i in range(building_ids_menu1.size()): 
		var button_path = "VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/TextureButton"
		var button = get_node(button_path) as TextureButton
		
		if button: 
			button.connect("pressed", _on_building_selected.bind(building_ids_menu1[i]))
			button.connect("mouse_entered", _on_building_hover.bind(building_ids_menu1[i], button))
			button.connect("mouse_exited", _on_building_hover_exit)
			
		var label_path = "VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/Label"
		var label = get_node(label_path) as Label
		
		if label: 
			var building_data = DataBuilding.get_building_data(building_ids_menu1[i])
			label.text = building_data.get("name", building_ids_menu1[i].capitalize())
		
	for i in range(building_ids_menu2.size()): 
		var button_path = "VBoxContainer/HBoxContainer/PanelContainer2/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/TextureButton"
		var button = get_node(button_path) as TextureButton
		
		if button:
			button.connect("pressed", _on_building_selected.bind(building_ids_menu2[i]))
			button.connect("mouse_entered", _on_building_hover.bind(building_ids_menu2[i], button))
			button.connect("mouse_exited", _on_building_hover_exit)
			
		var label_path = "VBoxContainer/HBoxContainer/PanelContainer2/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/Label"
		var label = get_node(label_path) as Label
	
		if label: 
			var building_data = DataBuilding.get_building_data(building_ids_menu2[i])
			label.text = building_data.get("name", building_ids_menu2[i].capitalize())
			
	button1.connect("pressed", _on_menu_button_pressed.bind(0))
	button2.connect("pressed", _on_menu_button_pressed.bind(1))

func _process(delta: float) -> void: 
	if current_state == BuildingState.BUILDING and building_preview:
		var mouse_pos = city_scene.get_global_mouse_position()
		
		if is_snapped and current_hover_area:
			var area_center = current_hover_area.get_global_center()
			var distance_to_area = mouse_pos.distance_to(area_center)
			
			if distance_to_area > snap_distance_threshold:
				is_snapped = false
				current_hover_area.show_highlight()
				current_hover_area = null
				building_preview.global_position = mouse_pos
				
				var sprite = building_preview.get_node("SpritePreview")
				if sprite:
					sprite.modulate = Color(1, 0.5, 0.5, 0.7)
			else:
				_snap_preview_to_area(current_hover_area)
		elif current_hover_area:
			is_snapped = true
			current_hover_area.hide_highlight()
			_snap_preview_to_area(current_hover_area)
			
			var sprite = building_preview.get_node("SpritePreview")
			if sprite:
				sprite.modulate = Color(0.5, 1, 0.5, 0.9)
		else:
			is_snapped = false
			building_preview.global_position = mouse_pos
			
			var sprite = building_preview.get_node("SpritePreview")
			if sprite:
				sprite.modulate = Color(1, 0.5, 0.5, 0.7)

func _toggle_menu(menu_index: int) -> void:
	var menu1 = $VBoxContainer/HBoxContainer/PanelContainer
	var menu2 = $VBoxContainer/HBoxContainer/PanelContainer2

	if menu_index == 0:
		menu1.visible = true
		menu2.visible = false
	else:
		menu1.visible = false
		menu2.visible = true

func _on_menu_button_pressed(menu_index: int) -> void:
	_toggle_menu(menu_index)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("construction_menu"):
		if city_scene and city_scene.visible and current_state == BuildingState.NORMAL:
			_toggle_construction_menu()
			
	if event.is_action_pressed("ui_cancel"):
		if city_scene and city_scene.visible:
			if current_state == BuildingState.NORMAL and visible:
				visible = false
			elif current_state == BuildingState.BUILDING:
				_exit_building_mode_to_menu()
			
	if city_scene and city_scene.visible and current_state == BuildingState.BUILDING:
		if event.is_action_pressed("cancel_construction"):
			_exit_building_mode_to_menu()
		elif event.is_action_pressed("ui_cancel"):
			_exit_building_mode_to_menu()
		elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			_try_place_building()

func _try_place_building() -> void: 
	if is_snapped and current_hover_area and not current_hover_area.is_occupied:
		# Usar BuildingSystem para construir
		if BuildingSystem.ref:
			var building = BuildingSystem.ref.construct_building(
				selected_building_id,
				current_hover_area.slot_id,
				building_preview.global_position
			)
			
			if building:
				_exit_building_mode_to_menu()
			else:
				print("No se pudo construir el edificio (recursos insuficientes)")

func _exit_building_mode_to_menu() -> void:
	_cleanup_building_mode()
	visible = true

func _update_available_areas() -> void:
	var building_data = DataBuilding.get_building_data(selected_building_id)
	if building_data.is_empty():
		return
	
	# Por ahora permitir construcción en cualquier slot libre
	for area in construction_areas:
		if not area.is_occupied:
			area.show_highlight()
		else:
			area.hide_highlight()

func _toggle_construction_menu() -> void: 
	visible = !visible

func _on_building_selected(building_key: String) -> void:
	var building_data = DataBuilding.get_building_data(building_key)
	if not building_data.is_empty():
		_start_building_mode(building_key)
	else:
		print("Building type not found: " + building_key)
	emit_signal("building_selected")

func _start_building_mode(building_id: String) -> void: 
	current_state = BuildingState.BUILDING
	selected_building_id = building_id
	construction_areas = get_tree().get_nodes_in_group("city_building_slots")
	visible = false
	_show_all_available_areas()
	_create_building_preview(building_id)

func _show_all_available_areas() -> void: 
	for area in construction_areas:
		if area is CityBuildingSlot:  # CAMBIADO: Verificar que es CityBuildingSlot
			if not area.is_occupied:
				area.show_highlight()

func _create_building_preview(building_id: String) -> void: 
	if building_preview: 
		building_preview.queue_free()
		building_preview = null
	
	building_preview = Area2D.new()
	building_preview.name = "BuildingPreview"
	building_preview.collision_layer = 2
	building_preview.collision_mask = 1
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 50)
	collision.shape = shape
	collision.name = "PreviewCollision"
	building_preview.add_child(collision)
		
	var sprite = Sprite2D.new()
	var building_data = DataBuilding.get_building_data(building_id)
	var texture_path = building_data.get("texture_path", "")
	if texture_path != "" and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	
	sprite.modulate.a = 0.7
	sprite.scale = Vector2(0.5, 0.5)
	sprite.name = "SpritePreview"
	building_preview.add_child(sprite)
	
	building_preview.area_entered.connect(_on_preview_entered_area)
	building_preview.area_exited.connect(_on_preview_exited_area)
	
	var scene_manager = get_tree().get_first_node_in_group("scene_manager")
	if not scene_manager:
		scene_manager = get_parent().get_parent()
	
	scene_manager.add_child(building_preview)

func _on_preview_entered_area(area: Area2D) -> void:
	if area is CityBuildingSlot and not is_snapped:  # CAMBIADO: CityBuildingSlot en lugar de ConstructionArea
		var construction_area = area as CityBuildingSlot
		
		if construction_area.is_occupied:
			return
		
		current_hover_area = construction_area

func _on_preview_exited_area(area: Area2D) -> void:
	pass

func _cancel_building_mode() -> void: 	
	_cleanup_building_mode()
	visible = false

func _cleanup_building_mode() -> void:
	if is_snapped and current_hover_area:
		current_hover_area.show_highlight()
	
	if building_preview:
		building_preview.queue_free()
		building_preview = null
	
	current_state = BuildingState.NORMAL
	selected_building_id = ""
	current_hover_area = null
	is_snapped = false
	
	$VBoxContainer.modulate.a = 1.0
	
	_hide_all_highlights()

func _hide_all_highlights() -> void: 
	for area in construction_areas: 
		if area is CityBuildingSlot:  # CAMBIADO: Verificar tipo correcto
			area.hide_highlight()

func _on_building_hover(building_key: String, button: TextureButton) -> void: 
	var building_data = DataBuilding.get_building_data(building_key)
	if not building_data.is_empty():
		_show_tooltip(building_data.get("description", ""), button)

func _on_building_hover_exit() -> void: 
	tooltip.visible = false

func _show_tooltip(description: String, button: TextureButton) -> void: 
	tooltip.get_node("MarginContainer/Label").text = description
	tooltip.visible = true
	
	var button_global_pos = button.global_position
	var button_size = button.size
	
	tooltip.position.x = button_global_pos.x
	tooltip.position.y = button_global_pos.y - tooltip.size.y - 30

func _snap_preview_to_area(area: CityBuildingSlot) -> void:  # CAMBIADO: CityBuildingSlot
	if building_preview and area:
		var snap_position = area.get_global_center()
		
		building_preview.global_position = snap_position
		building_preview.rotation = area.rotation
		
		var sprite = building_preview.get_node("SpritePreview")
		if sprite:
			sprite.modulate = Color(0.5, 1, 0.5, 0.9)
