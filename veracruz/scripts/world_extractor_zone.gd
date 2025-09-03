class_name WorldExtractorZone
extends Area2D

signal zone_clicked(zone: WorldExtractorZone)

enum ZoneState {
	LOCKED,     # No conquistada
	UNLOCKED,   # Conquistada pero sin construir
	BUILT       # Con extractor construido
}

@export_enum("lumbermill", "quarry", "plantation") var zone_category : String = "lumbermill"
@export var zone_name : String = "Zona Norte"
@export var zone_state : ZoneState = ZoneState.LOCKED
@export var is_initial_zone : bool = false  # Si empieza desbloqueada

var zone_id : String = ""
var current_extractor_id : String = ""  # ID del extractor construido aquí
var visual_container : Node2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	
	zone_id = "zone_%s_%d" % [zone_category, get_instance_id()]
	
	add_to_group("world_extractor_zones")
	
	visual_container = Node2D.new()
	visual_container.name = "VisualContainer"
	add_child(visual_container)
	
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# DIFERIR la inicialización del estado para asegurar que los sistemas estén listos
	call_deferred("_initialize_zone_state")

func _initialize_zone_state() -> void:
	# Ahora sí verificar el estado con los sistemas ya creados
	if is_initial_zone:
		zone_state = ZoneState.UNLOCKED
		if ExtractorSystem.ref and Game.ref and Game.ref.data.progression:
			# Asegurar que la zona está en el array
			if zone_id not in Game.ref.data.progression.unlocked_zones:
				Game.ref.data.progression.unlocked_zones.append(zone_id)
	else:
		if ExtractorSystem.ref and ExtractorSystem.ref.is_zone_unlocked(zone_id):
			zone_state = ZoneState.UNLOCKED
	
	# Verificar si hay extractor construido
	if ExtractorSystem.ref:
		var extractor = ExtractorSystem.ref.get_extractor_at_zone(zone_id)
		if extractor:
			zone_state = ZoneState.BUILT
			current_extractor_id = extractor.instance_id
		
		# Conectar señales solo si el sistema existe
		if not ExtractorSystem.ref.extractor_constructed.is_connected(_on_extractor_constructed):
			ExtractorSystem.ref.extractor_constructed.connect(_on_extractor_constructed)
		if not ExtractorSystem.ref.extractor_demolished.is_connected(_on_extractor_demolished):
			ExtractorSystem.ref.extractor_demolished.connect(_on_extractor_demolished)
	
	_update_visual()

func _update_visual() -> void:
	# Limpiar visuales anteriores
	for child in visual_container.get_children():
		child.queue_free()
	
	var visual = ColorRect.new()
	visual.size = Vector2(100, 100)
	visual.position = Vector2(-50, -50)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 24)
	
	match zone_state:
		ZoneState.LOCKED:
			visual.color = Color(0.3, 0.3, 0.3, 0.7)
			label.text = "🔒"
			label.position = Vector2(-12, -12)
			
		ZoneState.UNLOCKED:
			visual.color = Color(0.5, 0.8, 0.5, 0.3)
			label.text = "+"
			label.add_theme_font_size_override("font_size", 48)
			label.position = Vector2(-12, -24)
			
		ZoneState.BUILT:
			match zone_category:
				"lumbermill":
					visual.color = Color(0.4, 0.2, 0.1, 0.8)
				"quarry":
					visual.color = Color(0.5, 0.5, 0.5, 0.8)
				"plantation":
					visual.color = Color(0.2, 0.5, 0.2, 0.8)
			
			if ExtractorSystem.ref:
				var extractor = ExtractorSystem.ref.get_extractor_by_id(current_extractor_id)
				if extractor:
					label.text = extractor.selected_resource
					label.add_theme_font_size_override("font_size", 12)
					label.position = Vector2(-40, -5)
	
	visual_container.add_child(visual)
	visual_container.add_child(label)

func _on_mouse_entered() -> void:
	modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			_handle_click()

func _handle_click() -> void:
	# Verificar que los sistemas necesarios existen antes de mostrar popups
	if not PopupManager.ref:
		push_error("PopupManager not initialized")
		return
		
	match zone_state:
		ZoneState.LOCKED:
			_show_conquest_popup()
		ZoneState.UNLOCKED:
			_show_build_popup()
		ZoneState.BUILT:
			_show_extractor_popup()

func _show_conquest_popup() -> void:
	if PopupManager.ref:
		PopupManager.ref.show_conquest_popup(zone_id, zone_name, ExtractorSystem.ZONE_CONQUEST_COST)

func _show_build_popup() -> void:
	if PopupManager.ref and ExtractorSystem.ref:
		var available = ExtractorSystem.ref.get_available_resources(zone_category)
		PopupManager.ref.show_resource_selection_popup(zone_id, zone_category, available)

func _show_extractor_popup() -> void:
	if PopupManager.ref and ExtractorSystem.ref:
		var extractor = ExtractorSystem.ref.get_extractor_by_id(current_extractor_id)
		if extractor:
			PopupManager.ref.show_extractor_management_popup(extractor)

func _on_extractor_constructed(extractor: ExtractorInstance) -> void:
	if extractor.zone_id == zone_id:
		zone_state = ZoneState.BUILT
		current_extractor_id = extractor.instance_id
		_update_visual()

func _on_extractor_demolished(extractor: ExtractorInstance) -> void:
	if extractor.instance_id == current_extractor_id:
		zone_state = ZoneState.UNLOCKED
		current_extractor_id = ""
		_update_visual()

func _exit_tree() -> void:
	# Desconectar señales al salir para evitar errores
	if ExtractorSystem.ref:
		if ExtractorSystem.ref.extractor_constructed.is_connected(_on_extractor_constructed):
			ExtractorSystem.ref.extractor_constructed.disconnect(_on_extractor_constructed)
		if ExtractorSystem.ref.extractor_demolished.is_connected(_on_extractor_demolished):
			ExtractorSystem.ref.extractor_demolished.disconnect(_on_extractor_demolished)
