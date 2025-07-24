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


func _process(delta: float) -> void: 
	if current_state == BuildingState.BUILDING and building_preview:
		var mouse_pos = city_scene.get_global_mouse_position()
		var valid_area = _find_closest_valid_area(mouse_pos)
		
		if valid_area:
			print("SNAP a: ", valid_area.name)
			_snap_preview_to_area(valid_area)
		else:
			building_preview.global_position = mouse_pos
			
func _find_closest_valid_area(mouse_pos: Vector2) -> ConstructionArea:
	var building_data = buildings.get(selected_building_id, {})
	var allowed_types = building_data.get("allowed_area_types", [])
	var closest_area = null
	var min_distance = 100.0  # distancia máxima para snap
	
	var areas = get_tree().get_nodes_in_group("construction_areas")
	for area in areas:
		if not area.is_occupied and area.area_type in allowed_types:
			# Convertir mouse_pos a coordenadas locales del área
			var local_pos = area.to_local(mouse_pos)
			var collision_shape = area.get_node("CollisionShape2D")
			
			if collision_shape and collision_shape.shape is RectangleShape2D:
				var rect = Rect2(-collision_shape.shape.size/2, collision_shape.shape.size)
				if rect.has_point(local_pos):
					var distance = area.global_position.distance_to(mouse_pos)
					if distance < min_distance:
						min_distance = distance
						closest_area = area
	
	return closest_area
		
func _on_menu_button_pressed(menu_index: int) -> void:
	_toggle_menu(menu_index)

func _toggle_menu(menu_index: int) -> void:
	
	var menu1 = $VBoxContainer/HBoxContainer/PanelContainer
	var menu2 = $VBoxContainer/HBoxContainer/PanelContainer2

	if menu_index == 0:
		menu1.visible = true
		menu2.visible = false
	else:
		menu1.visible = false
		menu2.visible = true
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("construction_menu"):
		if city_scene and city_scene.visible and current_state == BuildingState.NORMAL:
			_toggle_construction_menu()
			
	if city_scene and city_scene.visible and current_state == BuildingState.BUILDING:
		if event.is_action_pressed("cancel_construction"):
			_cancel_building_mode()


func _toggle_construction_menu() -> void: 
	visible = !visible
	
func _on_building_selected(building_key: String) -> void:
	var building_data = buildings.get(building_key, null)
	if building_data:
		print("Building selected: " + building_data["name"])
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
	
	print("Edificio seleccionado: ", selected_building_id)
	print("Tipos permitidos: ", allowed_types)
	
	for area in construction_areas:
		print("Área: ", area.name, " - Tipo: ", area.area_type, " - Ocupada: ", area.is_occupied)
		
		if not area.is_occupied and area.area_type in allowed_types:
			area.show_highlight()
			print("Mostrando área compatible: " + str(area.name))
		else:
			print("Área no compatible o ocupada: " + str(area.name))

func _create_building_preview(building_id: String) -> void: 
	if building_preview: 
		building_preview.queue_redraw()
		building_preview = null
	
	building_preview = Node2D.new()
	
	#TODO: mapear cada building a su textura correspondiente
	
	var sprite = Sprite2D.new()
	var building_data = buildings.get(building_id, {})
	var texture_path = building_data.get("texture_path", "")
	if texture_path != "":
		sprite.texture = load(texture_path)
	
	sprite.modulate.a = 0.7
	sprite.scale = Vector2(0.5, 0.5)
	
	# Añadir sprite como hijo del Node2D
	building_preview.add_child(sprite)
	
	var scene_manager = get_tree().get_first_node_in_group("scene_manager")
	if not scene_manager:
		scene_manager = get_parent().get_parent()
	
	scene_manager.add_child(building_preview)
	print("Preview creado para: " + building_id)
	
func _cancel_building_mode() -> void: 
	print("Construcción cancelada")
	
	current_state = BuildingState.NORMAL
	selected_building_id = ""
	
	$VBoxContainer.modulate.a = 1.0
	_hide_all_highlights()
	
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
		print("=== SNAP DEBUG ===")
		print("Área posición: ", area.global_position)
		print("Área center_position: ", area.center_position)
		print("Preview antes: ", building_preview.global_position)
		
		building_preview.global_position = area.global_position + area.center_position
		building_preview.rotation = area.rotation
		
		print("Preview después: ", building_preview.global_position)
		print("Preview visible: ", building_preview.visible)
