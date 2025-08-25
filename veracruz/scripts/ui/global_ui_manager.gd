class_name GlobalUIManager
extends CanvasLayer

@onready var top_ui = $UI/HBoxContainer/TopUI

var resource_labels : Dictionary = {}
var date_label : Label
var scene_button : Button

func _ready() -> void:
	# Esta es la UI global, siempre visible
	layer = 100
	
	# Crear la UI global
	_create_global_ui()
	
	# Conectar señales
	if ResourceManager.ref:
		ResourceManager.ref.resource_changed.connect(_on_resource_changed)
	if TickManager.ref:
		TickManager.ref.month_passed.connect(_update_date)

func _create_global_ui() -> void:
	if not top_ui:
		return
		
	# Limpiar el ColorRect temporal
	for child in top_ui.get_children():
		child.queue_free()
	
	# Crear HBox para organizar la barra superior
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 20)
	top_ui.add_child(main_hbox)
	
	# Panel de recursos (izquierda)
	var resources_panel = PanelContainer.new()
	var resources_hbox = HBoxContainer.new()
	resources_panel.add_child(resources_hbox)
	main_hbox.add_child(resources_panel)
	
	# Mostrar recursos principales
	var resources_to_show = ["wood", "stone", "tools", "piece_of_8"]
	for res in resources_to_show:
		var vbox = VBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = res.capitalize()
		name_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(name_label)
		
		var value_label = Label.new()
		var res_value = Game.ref.data.resources.get(res)
		if res_value == null:
			res_value = 0
		value_label.text = str(res_value)
		value_label.add_theme_font_size_override("font_size", 14)
		resource_labels[res] = value_label
		vbox.add_child(value_label)
		
		resources_hbox.add_child(vbox)
	
	# Espaciador central
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hbox.add_child(spacer)
	
	# Panel de fecha y controles (centro)
	var center_panel = PanelContainer.new()
	var center_vbox = VBoxContainer.new()
	center_panel.add_child(center_vbox)
	main_hbox.add_child(center_panel)
	
	# Fecha
	date_label = Label.new()
	date_label.text = "January, 1519"
	date_label.add_theme_font_size_override("font_size", 16)
	center_vbox.add_child(date_label)
	
	# Botones de velocidad
	var speed_hbox = HBoxContainer.new()
	center_vbox.add_child(speed_hbox)
	
	var pause_btn = Button.new()
	pause_btn.text = "||"
	pause_btn.pressed.connect(func(): TickManager.ref.set_game_speed(0))
	speed_hbox.add_child(pause_btn)
	
	var normal_btn = Button.new()
	normal_btn.text = ">"
	normal_btn.pressed.connect(func(): TickManager.ref.set_game_speed(1))
	speed_hbox.add_child(normal_btn)
	
	var fast_btn = Button.new()
	fast_btn.text = ">>"
	fast_btn.pressed.connect(func(): TickManager.ref.set_game_speed(2))
	speed_hbox.add_child(fast_btn)
	
	# Espaciador derecho
	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hbox.add_child(spacer2)
	
	# Panel de cambio de escena (derecha)
	var scene_panel = PanelContainer.new()
	var scene_hbox = HBoxContainer.new()
	scene_panel.add_child(scene_hbox)
	main_hbox.add_child(scene_panel)
	
	var city_btn = Button.new()
	city_btn.text = "Ciudad"
	city_btn.pressed.connect(_go_to_city)
	scene_hbox.add_child(city_btn)
	
	var world_btn = Button.new()
	world_btn.text = "Mundo"
	world_btn.pressed.connect(_go_to_world)
	scene_hbox.add_child(world_btn)

func _on_resource_changed(resource_name: String, new_amount: int, old_amount: int) -> void:
	if resource_name in resource_labels:
		resource_labels[resource_name].text = str(new_amount)

func _update_date() -> void:
	if date_label and TickManager.ref:
		date_label.text = TickManager.ref.get_date_string()

func _go_to_city() -> void:
	var city = get_node_or_null("/root/Game/SceneManager/CityScene")
	var world = get_node_or_null("/root/Game/SceneManager/WorldScene")
	
	if city and world:
		city.visible = true
		world.visible = false
		
		# NO mostrar UI de la ciudad automáticamente
		# El jugador la abrirá con B cuando quiera

func _go_to_world() -> void:
	var city = get_node_or_null("/root/Game/SceneManager/CityScene")
	var world = get_node_or_null("/root/Game/SceneManager/WorldScene")
	
	if city and world:
		# Cancelar modo construcción si está activo
		var city_ui = city.get_node_or_null("CityUIManager")
		if city_ui and city_ui.has_method("_cancel_building_mode"):
			city_ui._cancel_building_mode()
			city_ui.visible = false
		
		city.visible = false
		world.visible = true
