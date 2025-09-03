extends CanvasLayer

@onready var tooltip = $TooltipPanel
@onready var button1 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button
@onready var button2 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button2
@onready var city_scene: Node2D = $".."
@onready var city_sprite: Sprite2D = $"../CitySprite"

signal building_selected

var buildings: Dictionary = DataBuilding.BUILDINGS
var construction_areas: Array = []

enum BuildingState {
	NORMAL, 
	BUILDING
}

var current_state: BuildingState = BuildingState.NORMAL
var selected_building_id: String = ""
var building_preview: Node2D = null
var current_hover_area: CityBuildingSlot = null
var snap_distance_threshold: float = 100.0
var is_snapped: bool = false

func _ready() -> void:
	_toggle_menu(0)
	visible = false
	tooltip.visible = false
	
	var building_ids_menu1: Array = ["port", "tavern", "warehouse", "church"]
	var building_ids_menu2: Array = ["market", "carpentry", "forge", "mill"]
	
	# Configurar botones menú 1
	for i in range(building_ids_menu1.size()): 
		var button_path = "VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/TextureButton"
		var button = get_node_or_null(button_path) as TextureButton
		
		if button: 
			button.pressed.connect(_on_building_selected.bind(building_ids_menu1[i]))
			button.mouse_entered.connect(_on_building_hover.bind(building_ids_menu1[i], button))
			button.mouse_exited.connect(_on_building_hover_exit)
			
		var label_path = "VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/Label"
		var label = get_node_or_null(label_path) as Label
		
		if label: 
			var building_data = DataBuilding.get_building_data(building_ids_menu1[i])
			label.text = building_data.get("name", building_ids_menu1[i].capitalize())
	
	# Configurar botones menú 2
	for i in range(building_ids_menu2.size()): 
		var button_path = "VBoxContainer/HBoxContainer/PanelContainer2/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/TextureButton"
		var button = get_node_or_null(button_path) as TextureButton
		
		if button:
			button.pressed.connect(_on_building_selected.bind(building_ids_menu2[i]))
			button.mouse_entered.connect(_on_building_hover.bind(building_ids_menu2[i], button))
			button.mouse_exited.connect(_on_building_hover_exit)
			
		var label_path = "VBoxContainer/HBoxContainer/PanelContainer2/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/Label"
		var label = get_node_or_null(label_path) as Label
	
		if label: 
			var building_data = DataBuilding.get_building_data(building_ids_menu2[i])
			label.text = building_data.get("name", building_ids_menu2[i].capitalize())
	
	if button1:
		button1.pressed.connect(_on_menu_button_pressed.bind(0))
	if button2:
		button2.pressed.connect(_on_menu_button_pressed.bind(1))
	
	# Debug para verificar que encontramos el city_sprite
	if city_sprite:
		print("CitySprite found at scale: ", city_sprite.scale)
	else:
		push_warning("CitySprite not found!")

func _process(delta: float) -> void: 
	if current_state == BuildingState.BUILDING and building_preview:
		_update_building_preview()

func _update_building_preview() -> void:
	# Obtener posición del mouse en el mundo
	var mouse_pos = city_scene.get_global_mouse_position()
	
	# Buscar el slot válido más cercano
	var closest_slot : CityBuildingSlot = null
	var closest_distance : float = snap_distance_threshold
	
	for area in construction_areas:
		if area is CityBuildingSlot and not area.is_occupied:
			if area.can_place_building(selected_building_id):
				var slot_center = area.get_global_center()
				var distance = mouse_pos.distance_to(slot_center)
				if distance < closest_distance:
					closest_distance = distance
					closest_slot = area
	
	# Actualizar el estado del hover
	if closest_slot != current_hover_area:
		# Limpiar el slot anterior
		if current_hover_area:
			current_hover_area.hide_highlight()
		current_hover_area = closest_slot
	
	# Posicionar el preview
	if current_hover_area:
		is_snapped = true
		var snap_pos = current_hover_area.get_global_center()
		building_preview.global_position = snap_pos
		
		# No mostrar highlight cuando estamos snapeados
		current_hover_area.hide_highlight()
		
		# Visual verde para indicar que se puede construir
		var sprite = building_preview.get_node_or_null("SpritePreview")
		if sprite:
			sprite.modulate = Color(0.5, 1, 0.5, 0.9)
	else:
		is_snapped = false
		building_preview.global_position = mouse_pos
		
		# Visual rojo para indicar que no se puede construir
		var sprite = building_preview.get_node_or_null("SpritePreview")
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
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_place_building()

func _try_place_building() -> void: 
	if not is_snapped or not current_hover_area or current_hover_area.is_occupied:
		print("Cannot place: snapped=%s, area=%s" % [is_snapped, current_hover_area != null])
		return
	
	# Obtener la posición correcta del slot
	var build_position = current_hover_area.get_global_center()
	
	print("Attempting to build %s at slot %s, position %s" % [
		selected_building_id, 
		current_hover_area.slot_id, 
		build_position
	])
	
	# Marcar el slot como ocupado inmediatamente
	current_hover_area.place_building(selected_building_id)
	
	# Usar BuildingSystem para construir
	if BuildingSystem.ref:
		var building = BuildingSystem.ref.construct_building(
			selected_building_id,
			current_hover_area.slot_id,
			build_position
		)
		
		if building:
			print("Building constructed successfully")
			_exit_building_mode_to_menu()
		else:
			print("Failed to construct building (insufficient resources?)")
			# Revertir el estado del slot
			current_hover_area.is_occupied = false

func _exit_building_mode_to_menu() -> void:
	_cleanup_building_mode()
	visible = true

func _toggle_construction_menu() -> void: 
	visible = !visible

func _on_building_selected(building_key: String) -> void:
	var building_data = DataBuilding.get_building_data(building_key)
	if not building_data.is_empty():
		print("Selected building: %s" % building_key)
		_start_building_mode(building_key)
	else:
		print("Building type not found: " + building_key)
	emit_signal("building_selected")

func _start_building_mode(building_id: String) -> void: 
	current_state = BuildingState.BUILDING
	selected_building_id = building_id
	construction_areas = get_tree().get_nodes_in_group("city_building_slots")
	visible = false
	
	print("Starting building mode for: %s" % building_id)
	print("Found %d construction areas" % construction_areas.size())
	
	_show_available_areas_for_building(building_id)
	_create_building_preview(building_id)

func _show_available_areas_for_building(building_id: String) -> void:
	var available_count = 0
	for area in construction_areas:
		if area is CityBuildingSlot:
			if not area.is_occupied and area.can_place_building(building_id):
				area.show_highlight()
				available_count += 1
			else:
				area.hide_highlight()
	print("Available slots for %s: %d" % [building_id, available_count])

func _create_building_preview(building_id: String) -> void: 
	if building_preview: 
		building_preview.queue_free()
		building_preview = null
	
	building_preview = Node2D.new()
	building_preview.name = "BuildingPreview"
	building_preview.z_index = 10  # Asegurar que esté arriba
	
	var sprite = Sprite2D.new()
	sprite.name = "SpritePreview"
	
	var building_data = DataBuilding.get_building_data(building_id)
	var texture_path = building_data.get("texture_path", "")
	
	if texture_path != "" and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.scale = Vector2(0.25, 0.25)  # Misma escala que los edificios reales
	else:
		# Crear placeholder
		var placeholder = ColorRect.new()
		placeholder.size = Vector2(60, 60)
		placeholder.position = Vector2(-30, -30)
		placeholder.color = Color(0.7, 0.7, 0.3, 0.7)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		building_preview.add_child(placeholder)
		
		var label = Label.new()
		label.text = building_data.get("name", "Building")
		label.position = Vector2(-25, -5)
		label.add_theme_font_size_override("font_size", 10)
		building_preview.add_child(label)
	
	sprite.modulate.a = 0.7
	building_preview.add_child(sprite)
	
	# Añadir al CitySprite para que tenga la misma transformación
	if city_sprite:
		city_sprite.add_child(building_preview)
		print("Preview added to CitySprite")
	else:
		# Fallback: añadir al city_scene
		city_scene.add_child(building_preview)
		print("Preview added to CityScene (fallback)")

func _cancel_building_mode() -> void:
	_cleanup_building_mode()
	visible = false

func _cleanup_building_mode() -> void:
	if current_hover_area:
		current_hover_area.show_highlight()
		current_hover_area = null
	
	if building_preview:
		building_preview.queue_free()
		building_preview = null
	
	current_state = BuildingState.NORMAL
	selected_building_id = ""
	is_snapped = false
	
	_hide_all_highlights()

func _hide_all_highlights() -> void: 
	for area in construction_areas: 
		if area is CityBuildingSlot:
			area.hide_highlight()

func _on_building_hover(building_key: String, button: TextureButton) -> void: 
	var building_data = DataBuilding.get_building_data(building_key)
	if not building_data.is_empty():
		_show_tooltip(building_data.get("description", ""), button)

func _on_building_hover_exit() -> void: 
	if tooltip:
		tooltip.visible = false

func _show_tooltip(description: String, button: TextureButton) -> void:
	if not tooltip:
		return
		 
	var label = tooltip.get_node_or_null("MarginContainer/Label")
	if label:
		label.text = description
	
	tooltip.visible = true
	tooltip.position.x = button.global_position.x
	tooltip.position.y = button.global_position.y - tooltip.size.y - 30

func _snap_preview_to_area(area: CityBuildingSlot) -> void:
	if building_preview and area:
		var snap_position = area.get_global_center()
		building_preview.global_position = snap_position
