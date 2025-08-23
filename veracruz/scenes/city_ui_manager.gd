extends CanvasLayer

@onready var tooltip = $TooltipPanel
@onready var button1 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button
@onready var button2 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button2
@onready var city_scene: Node2D = $".."


signal building_selected

var buildings: Dictionary = {
	"Port": {
		"name": "Port", 
		"description": "Permite el comercio marítimo y la llegada de nuevos colonos. Genera ingresos por comercio.",
		"texture_path": "res://assets/buildings/PuertoAstillero_Lvl_1.png",
		"allowed_area_types": [5]
		},
	"Tabern": {
		"name": "Tabern", 
		"description": "Lugar de encuentro social donde los colonos se reúnen. Mejora el bienestar y la información comercial.",
		"texture_path": "res://assets/buildings/Taberna_Lvl_1.png",
		"allowed_area_types": ""
		}, 
	"Lighthouse": {
		"name": "Lighthouse", 
		"description": "Guía a los barcos hacia el puerto de forma segura. Reduce el riesgo de naufragios y aumenta el comercio.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Wall": {
		"name": "Wall", 
		"description": "Fortificación defensiva que protege la ciudad de ataques piratas y potencias enemigas.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Palace": {
		"name": "Palace", 
		"description": "Residencia del Virrey. Centro del poder colonial que aumenta la influencia política de la ciudad.",
		"texture_path": "res://assets/buildings/Casa_Del_Gobernador_Lvl_1.png",
		"allowed_area_types": ""
		}, 
	"Church": {
		"name": "Church", 
		"description": "Centro espiritual de la colonia. Evangeliza a los nativos y mejora la moral de los colonos.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Warehouse": {
		"name": "Warehouse", 
		"description": "Aumenta la capacidad de almacenamiento de mercancías antes de enviarlas a España.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Hospital": {
		"name": "Hospital", 
		"description": "Atiende a enfermos y heridos. Reduce la mortalidad y mejora la salud de la población.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"CityHall": {
		"name": "CityHall", 
		"description": "Sede del gobierno local. Permite decretar ordenanzas y gestionar los asuntos municipales.",
		"texture_path": "res://assets/buildings/Ayuntamiento_Lvl_1.png",
		"allowed_area_types": ""
		}, 
	"Market": {
		"name": "Market", 
		"description": "Plaza comercial donde se intercambian productos locales. Centro económico de la ciudad.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Weaving": {
		"name": "Weaving", 
		"description": "Transforma algodón en telas y textiles. Produce ropa para los colonos y productos de exportación.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Carpentry": {
		"name": "Carpentry", 
		"description": "Procesa madera para crear herramientas, muebles y materiales de construcción.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Forge": {
		"name": "Forge", 
		"description": "Forja herramientas y armas de metal. Esencial para el desarrollo agrícola y la defensa.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Distillery": {
		"name": "Distillery", 
		"description": "Produce bebidas alcohólicas como aguardiente. Genera ingresos y mejora la moral colonial.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	"Mill": {
		"name": "Mill", 
		"description": "Procesa granos para convertirlos en harina. Base de la alimentación de la población.",
		"texture_path": "",
		"allowed_area_types": ""
		}, 
	}
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
var current_hover_area: ConstructionArea = null
var snap_distance_threshold: float = 150.0  # Distancia para mantener el snap
var is_snapped: bool = false

func _ready() -> void:
	
	_toggle_menu(0)
	visible = false
	tooltip.visible = false
	
	var building_ids_menu1: Array = ["Port", "Tabern", "Lighthouse", "Wall", "Palace", "Church", "Warehouse", "Hospital"]
	var building_ids_menu2: Array = ["CityHall", "Market", "Weaving", "Carpentry", "Forge", "Distillery", "Mill"]
	
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
			label.text = str(building_ids_menu1[i])
		
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
			label.text = str(building_ids_menu2[i])
			
	button1.connect("pressed", _on_menu_button_pressed.bind(0))
	button2.connect("pressed", _on_menu_button_pressed.bind(1))

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
			
	if city_scene and city_scene.visible and current_state == BuildingState.BUILDING:
		if event.is_action_pressed("cancel_construction"):
			_cancel_building_mode()
		elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			_try_place_building()

func _try_place_building() -> void: 
		# Solo construir si estamos en snap con un área válida
	if is_snapped and current_hover_area and not current_hover_area.is_occupied:
		# Obtener datos del edificio
		var building_data = buildings.get(selected_building_id, {})
		var texture_path = building_data.get("texture_path", "")
		
		# Crear el edificio real
		var new_building = Node2D.new()
		new_building.name = selected_building_id + "_" + str(Time.get_ticks_msec())
		
		# Añadir sprite al edificio
		var sprite = Sprite2D.new()
		if texture_path != "":
			sprite.texture = load(texture_path)
		sprite.scale = Vector2(0.5, 0.5)
		new_building.add_child(sprite)
		
		# Posicionar el edificio donde está el preview
		new_building.global_position = building_preview.global_position
		new_building.rotation = building_preview.rotation
		
		# Añadir el edificio a la escena
		city_scene.add_child(new_building)
		
		# Marcar el área como ocupada
		current_hover_area.is_occupied = true
		current_hover_area.hide_highlight()
		
		# Guardar referencia del edificio en el área (opcional, útil para futuro)
		current_hover_area.set_meta("building", new_building)
		
		# Reset para poder construir otro
		is_snapped = false
		current_hover_area = null
		
		# Actualizar las áreas disponibles (ocultar las ocupadas)
		_update_available_areas()
		
func _update_available_areas() -> void:
	var building_data = buildings.get(selected_building_id, {})
	var allowed_types = building_data.get("allowed_area_types", [])
	
	for area in construction_areas:
		if not area.is_occupied and area.area_type in allowed_types:
			area.show_highlight()
		else:
			area.hide_highlight()
func _toggle_construction_menu() -> void: 
	visible = !visible
func _on_building_selected(building_key: String) -> void:
	var building_data = buildings.get(building_key, null)
	if building_data:
		_start_building_mode(building_key)
	emit_signal("building_selected")
func _start_building_mode(building_id: String) -> void: 
	current_state = BuildingState.BUILDING
	selected_building_id = building_id
	construction_areas = get_tree().get_nodes_in_group("construction_areas")
	# TODO: animación cuando selecciono el edificio 
	#$VBoxContainer.modulate.a = 0.8
	visible = false
	_show_all_available_areas()
	_create_building_preview(building_id)
	
	print ("Modo construcción para: " + building_id)
func _show_all_available_areas() -> void: 
	var building_data = buildings.get(selected_building_id, {})
	var allowed_types = building_data.get("allowed_area_types", [])
		
	for area in construction_areas:		
		if not area.is_occupied and area.area_type in allowed_types:
			area.show_highlight()
func _create_building_preview(building_id: String) -> void: 
	if building_preview: 
		building_preview.queue_free()
		building_preview = null
	
	building_preview = Area2D.new()
	building_preview.name = "BuildingPreview"
	building_preview.collision_layer = 2
	building_preview.collision_mask = 4
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 50)
	collision.shape = shape
	collision.name = "PreviewCollision"
	building_preview.add_child(collision)
		
	var sprite = Sprite2D.new()
	var building_data = buildings.get(building_id, {})
	var texture_path = building_data.get("texture_path", "")
	if texture_path != "":
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
	if area is ConstructionArea and not is_snapped:
		var construction_area = area as ConstructionArea
		
		# No hacer snap en áreas ocupadas
		if construction_area.is_occupied:
			return
			
		var building_data = buildings.get(selected_building_id, {})
		var allowed_types = building_data.get("allowed_area_types", [])
		
		if construction_area.area_type in allowed_types:
			current_hover_area = construction_area
func _on_preview_exited_area(area: Area2D) -> void:
	pass
func _cancel_building_mode() -> void: 	
	# Si estábamos en snap, mostrar el highlight de nuevo antes de ocultarlo
	if is_snapped and current_hover_area:
		current_hover_area.show_highlight()
	
	current_state = BuildingState.NORMAL
	selected_building_id = ""
	current_hover_area = null
	is_snapped = false
	
	$VBoxContainer.modulate.a = 1.0
	_hide_all_highlights()  # Esto ocultará todos los highlights
	
	visible = true
	if building_preview: 
		building_preview.queue_free()
		building_preview = null
func _hide_all_highlights() -> void: 
	for area in construction_areas: 
		area.hide_highlight()	
func _on_building_hover(building_key: String, button: TextureButton) -> void: 
	var building_data = buildings.get(building_key, null)
	if building_data:
		_show_tooltip(building_data["description"], button)
func _on_building_hover_exit() -> void: 
	tooltip.visible = false
func _show_tooltip(description: String, button: TextureButton) -> void: 
	tooltip.get_node("MarginContainer/Label").text = description
	tooltip.visible = true
	
	var button_global_pos = button.global_position
	var button_size = button.size
	
	tooltip.position.x = button_global_pos.x
	tooltip.position.y = button_global_pos.y - tooltip.size.y - 30
func _snap_preview_to_area(area: ConstructionArea) -> void:
	if building_preview and area:
		# Usar la posición global del centro directamente
		var snap_position = area.get_global_center()
		
		building_preview.global_position = snap_position
		building_preview.rotation = area.rotation
