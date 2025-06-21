extends CanvasLayer

@onready var tooltip = $TooltipPanel
@onready var button1 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button
@onready var button2 = $VBoxContainer/HBoxContainer/SideButtons/VBoxContainer/Button2

signal building_selected

var buildings: Dictionary = {
	"Port": {"name": "Port", "description": "Permite el comercio marítimo y la llegada de nuevos colonos. Genera ingresos por comercio."},
	"Lighthouse": {"name": "Lighthouse", "description": "Guía a los barcos hacia el puerto de forma segura. Reduce el riesgo de naufragios y aumenta el comercio."}, 
	"Wall": {"name": "Wall", "description": "Fortificación defensiva que protege la ciudad de ataques piratas y potencias enemigas."}, 
	"Tabern": {"name": "Tabern", "description": "Lugar de encuentro social donde los colonos se reúnen. Mejora el bienestar y la información comercial."}, 
	"Palace": {"name": "Palace", "description": "Residencia del Virrey. Centro del poder colonial que aumenta la influencia política de la ciudad."}, 
	"Church": {"name": "Church", "description": "Centro espiritual de la colonia. Evangeliza a los nativos y mejora la moral de los colonos."}, 
	"Warehouse": {"name": "Warehouse", "description": "Aumenta la capacidad de almacenamiento de mercancías antes de enviarlas a España."}, 
	"Hospital": {"name": "Hospital", "description": "Atiende a enfermos y heridos. Reduce la mortalidad y mejora la salud de la población."}, 
	"CityHall": {"name": "CityHall", "description": "Sede del gobierno local. Permite decretar ordenanzas y gestionar los asuntos municipales."}, 
	"Market": {"name": "Market", "description": "Plaza comercial donde se intercambian productos locales. Centro económico de la ciudad."}, 
	"Weaving": {"name": "Weaving", "description": "Transforma algodón en telas y textiles. Produce ropa para los colonos y productos de exportación."}, 
	"Carpentry": {"name": "Carpentry", "description": "Procesa madera para crear herramientas, muebles y materiales de construcción."}, 
	"Forge": {"name": "Forge", "description": "Forja herramientas y armas de metal. Esencial para el desarrollo agrícola y la defensa."}, 
	"Distillery": {"name": "Distillery", "description": "Produce bebidas alcohólicas como aguardiente. Genera ingresos y mejora la moral colonial."}, 
	"Mill": {"name": "Mill", "description": "Procesa granos para convertirlos en harina. Base de la alimentación de la población."}, 
	}
	
## BUILDING STATE MACHINE

# Construction States

enum BuildingState {
	NORMAL, 
	BUILDING
}

# State variables 

var current_state: BuildingState = BuildingState.NORMAL
var selected_building_id: String = ""
var building_preview: Sprite2D = null

func _ready() -> void:
	
	_toggle_menu(0)
	visible = false
	tooltip.visible = false
	
	var building_ids_menu1: Array = ["Port", "Lighthouse", "Wall", "Tabern", "Palace", "Church", "Warehouse", "Hospital"]
	var building_ids_menu2: Array = ["CityHall", "Market", "Weaving", "Carpentry", "Forge", "Distillery", "Mill"]
	
	for i in range(building_ids_menu1.size()): 
		var button_path = "VBoxContainer/HBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/TextureButton"
		var button = get_node(button_path) as TextureButton
		
		if button: 
			button.connect("pressed", _on_building_selected.bind(building_ids_menu1[i]))
			button.connect("mouse_entered", _on_building_hover.bind(building_ids_menu1[i], button))
			button.connect("mouse_exited", _on_building_hover_exit)
	
	for i in range(building_ids_menu2.size()): 
		var button_path = "VBoxContainer/HBoxContainer/PanelContainer2/HBoxContainer2/HBoxContainer/Building" + str(i) + "/VBoxContainer/TextureButton"
		var button = get_node(button_path) as TextureButton
		
		if button:
			button.connect("pressed", _on_building_selected.bind(building_ids_menu2[i]))
			button.connect("mouse_entered", _on_building_hover.bind(building_ids_menu2[i], button))
			button.connect("mouse_exited", _on_building_hover_exit)
			
	button1.connect("pressed", _on_menu_button_pressed.bind(0))
	button2.connect("pressed", _on_menu_button_pressed.bind(1))

func _process(delta: float) -> void: 
	if current_state == BuildingState.BUILDING and building_preview: 
		building_preview.global_position = get_viewport().get_mouse_position()
		
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
		if current_state == BuildingState.NORMAL:
			_toggle_construction_menu()
			
	if current_state == BuildingState.BUILDING:
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
	
	# TODO: animación cuando selecciono el edificio 
	#$VBoxContainer.modulate.a = 0.8
	visible = false
	
	_create_building_preview(building_id)
	
	print ("Modo construcción para: " + building_id)
	
func _create_building_preview(building_id: String) -> void: 
	if building_preview: 
		building_preview.queue_redraw()
		building_preview = null
		
	building_preview = Sprite2D.new()
	
	#TODO: mapear cada building a su textura correspondiente
	
	building_preview.texture = load("res://assets/buildings/PuertoAstillero_Lvl_1.png")
	
	building_preview.modulate.a = 0.8
	building_preview.z_index = 100
	building_preview.scale = Vector2(0.25, 0.25)
	
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
	
	visible = true
	if building_preview: 
		building_preview.queue_free()
		building_preview = null
		
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
