class_name PopupManager
extends CanvasLayer

static var ref : PopupManager

var current_popup : Control = null

func _init() -> void:
	if ref == null:
		ref = self
	else:
		queue_free()

func _ready():
	layer = 10

# ============================================
# MÉTODO QUE FALTABA - show_extractor_popup
# ============================================

func show_extractor_popup(zone_id: String, zone_type: String, level: int = 0):
	print("Opening extractor popup for zone: %s, type: %s, level: %d" % [zone_id, zone_type, level])
	close_current_popup()
	
	# Buscar si ya existe un extractor en esta zona
	if ExtractorSystem.ref:
		var extractor = ExtractorSystem.ref.get_extractor_at_zone(zone_id)
		if extractor:
			# Si existe, mostrar el popup de gestión
			show_extractor_management_popup(extractor)
			return
	
	# Si no existe extractor, crear popup básico
	var popup = _create_extractor_popup()
	popup.setup_zone(zone_id, zone_type, level)
	
	add_child(popup)
	
	await get_tree().process_frame
	_center_popup(popup)
	
	# Conectar señales
	popup.closed.connect(_on_popup_closed)
	popup.upgrade_requested.connect(_on_upgrade_requested)
	popup.abandon_requested.connect(_on_abandon_requested)
	
	current_popup = popup

# ============================================
# POPUPS PARA ZONAS DEL MUNDO
# ============================================

func show_conquest_popup(zone_id: String, zone_name: String, cost: Dictionary):
	close_current_popup()
	
	var popup = _create_conquest_popup(zone_id, zone_name, cost)
	add_child(popup)
	
	await get_tree().process_frame
	_center_popup(popup)
	current_popup = popup

func show_resource_selection_popup(zone_id: String, category: String, available_resources: Array):
	close_current_popup()
	
	var popup = _create_resource_selection_popup(zone_id, category, available_resources)
	add_child(popup)
	
	await get_tree().process_frame
	_center_popup(popup)
	current_popup = popup

func show_extractor_management_popup(extractor: ExtractorInstance):
	close_current_popup()
	
	var popup = _create_extractor_management_popup(extractor)
	add_child(popup)
	
	await get_tree().process_frame
	_center_popup(popup)
	current_popup = popup

# ============================================
# POPUPS PARA EDIFICIOS
# ============================================

func show_building_popup(building: BuildingInstance):
	close_current_popup()
	
	var popup = _create_building_management_popup(building)
	add_child(popup)
	
	await get_tree().process_frame
	_center_popup(popup)
	current_popup = popup

# ============================================
# FUNCIONES HELPER
# ============================================

func close_current_popup():
	if current_popup:
		current_popup.queue_free()
		current_popup = null

func _center_popup(popup: Control) -> void:
	var viewport_size = Vector2(get_viewport().size)
	var popup_size = Vector2(popup.size)
	popup.position = (viewport_size - popup_size) / 2

func _on_popup_closed():
	current_popup = null

func _on_upgrade_requested(zone_id: String):
	if ExtractorSystem.ref:
		var extractor = ExtractorSystem.ref.get_extractor_at_zone(zone_id)
		if extractor:
			ExtractorSystem.ref.upgrade_extractor(extractor.instance_id)
	
	print("Upgrade requested for zone: " + zone_id)
	close_current_popup()

func _on_abandon_requested(zone_id: String):
	if ExtractorSystem.ref:
		var extractor = ExtractorSystem.ref.get_extractor_at_zone(zone_id)
		if extractor:
			ExtractorSystem.ref.demolish_extractor(extractor.instance_id)
	
	print("Abandon zone: " + zone_id)
	close_current_popup()

# ============================================
# CREACIÓN DE POPUPS PROGRAMÁTICOS
# ============================================

func _create_extractor_popup() -> ExtractorPopup:
	var popup = ExtractorPopup.new()
	popup.name = "ExtractorPopup"
	
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.name = "Header"
	vbox.add_child(header)
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "Extractor"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	
	header.add_spacer(false)
	
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "X"
	header.add_child(close_btn)
	
	vbox.add_child(HSeparator.new())
	
	# Descripción
	var desc = Label.new()
	desc.name = "DescriptionLabel"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	# Recurso
	var resource = Label.new()
	resource.name = "ResourceLabel"
	vbox.add_child(resource)
	
	vbox.add_child(HSeparator.new())
	
	# Workers section
	var workers_section = VBoxContainer.new()
	workers_section.name = "WorkersSection"
	vbox.add_child(workers_section)
	
	var workers_label = Label.new()
	workers_label.name = "WorkersLabel"
	workers_section.add_child(workers_label)
	
	var slider = HSlider.new()
	slider.name = "WorkersSlider"
	slider.min_value = 0
	slider.step = 1
	workers_section.add_child(slider)
	
	# Producción
	var prod = Label.new()
	prod.name = "ProductionLabel"
	vbox.add_child(prod)
	
	vbox.add_child(HSeparator.new())
	
	# Botones
	var buttons = HBoxContainer.new()
	buttons.name = "ButtonsContainer"
	vbox.add_child(buttons)
	
	var upgrade = Button.new()
	upgrade.name = "UpgradeButton"
	upgrade.text = "Mejorar"
	buttons.add_child(upgrade)
	
	buttons.add_spacer(false)
	
	var abandon = Button.new()
	abandon.name = "AbandonButton"
	abandon.text = "Abandonar"
	buttons.add_child(abandon)
	
	print("Popup structure created")
	
	return popup

func _create_conquest_popup(zone_id: String, zone_name: String, cost: Dictionary) -> Control:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(400, 200)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "Conquistar %s" % zone_name
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	var desc = Label.new()
	desc.text = "¿Deseas conquistar esta zona?"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var cost_label = Label.new()
	var cost_text = "Costo: "
	for resource in cost:
		cost_text += "%d %s " % [cost[resource], resource]
	cost_label.text = cost_text
	vbox.add_child(cost_label)
	
	vbox.add_child(HSeparator.new())
	
	var buttons = HBoxContainer.new()
	vbox.add_child(buttons)
	
	var confirm = Button.new()
	confirm.text = "Conquistar"
	confirm.pressed.connect(func():
		if ExtractorSystem.ref and ExtractorSystem.ref.unlock_zone(zone_id):
			var zones = get_tree().get_nodes_in_group("world_extractor_zones")
			for zone in zones:
				if zone.zone_id == zone_id:
					zone.zone_state = WorldExtractorZone.ZoneState.UNLOCKED
					zone._update_visual()
					break
			close_current_popup()
		else:
			print("No puedes pagar el costo de conquista")
	)
	buttons.add_child(confirm)
	
	buttons.add_spacer(false)
	
	var cancel = Button.new()
	cancel.text = "Cancelar"
	cancel.pressed.connect(close_current_popup)
	buttons.add_child(cancel)
	
	return popup

func _create_resource_selection_popup(zone_id: String, category: String, available_resources: Array) -> Control:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "Construir %s" % DataExtractor.get_extractor_data(category).get("name", "Extractor")
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	vbox.add_child(scroll)
	
	var resource_list = VBoxContainer.new()
	scroll.add_child(resource_list)
	
	var button_group = ButtonGroup.new()
	var selected_resource = ""
	
	var all_resources = DataExtractor.get_extractor_data(category).get("available_resources", [])
	
	for resource in all_resources:
		var hbox = HBoxContainer.new()
		resource_list.add_child(hbox)
		
		var radio = CheckBox.new()
		radio.button_group = button_group
		radio.disabled = resource not in available_resources
		
		if not radio.disabled and selected_resource.is_empty():
			selected_resource = resource
			radio.button_pressed = true
		
		radio.toggled.connect(func(pressed):
			if pressed:
				selected_resource = resource
		)
		hbox.add_child(radio)
		
		var label = Label.new()
		label.text = resource.capitalize()
		if resource not in available_resources:
			label.text += " (Bloqueado - Requiere investigación)"
			label.modulate = Color(0.5, 0.5, 0.5)
		hbox.add_child(label)
	
	var cost_label = Label.new()
	var construction_cost = DataExtractor.get_extractor_data(category).get("construction_cost", {})
	var cost_text = "Costo de construcción: "
	for res in construction_cost:
		cost_text += "%d %s " % [construction_cost[res], res]
	cost_label.text = cost_text
	vbox.add_child(cost_label)
	
	vbox.add_child(HSeparator.new())
	
	var buttons = HBoxContainer.new()
	vbox.add_child(buttons)
	
	var build = Button.new()
	build.text = "Construir"
	build.pressed.connect(func():
		if selected_resource.is_empty():
			print("Debes seleccionar un recurso")
			return
			
		var zone_node = null
		var zones = get_tree().get_nodes_in_group("world_extractor_zones")
		for zone in zones:
			if zone.zone_id == zone_id:
				zone_node = zone
				break
		
		if zone_node and ExtractorSystem.ref:
			var extractor = ExtractorSystem.ref.construct_extractor(
				category,
				selected_resource,
				zone_id,
				zone_node.global_position
			)
			
			if extractor:
				close_current_popup()
			else:
				print("No se pudo construir el extractor")
	)
	buttons.add_child(build)
	
	buttons.add_spacer(false)
	
	var cancel = Button.new()
	cancel.text = "Cancelar"
	cancel.pressed.connect(close_current_popup)
	buttons.add_child(cancel)
	
	return popup

func _create_extractor_management_popup(extractor: ExtractorInstance) -> Control:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(400, 350)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var title = Label.new()
	title.text = extractor.get_display_name() + " - Nivel " + str(extractor.current_level + 1)
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	var prod_label = Label.new()
	prod_label.text = "Producción: %d %s/tick" % [extractor.get_current_production(), extractor.selected_resource]
	vbox.add_child(prod_label)
	
	var workers_label = Label.new()
	workers_label.text = "Workers: %d / %d" % [extractor.assigned_workers, extractor.get_max_workers()]
	vbox.add_child(workers_label)
	
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = extractor.get_max_workers()
	slider.value = extractor.assigned_workers
	slider.step = 1
	slider.value_changed.connect(func(value):
		extractor.set_workers(int(value))
		workers_label.text = "Workers: %d / %d" % [int(value), extractor.get_max_workers()]
		prod_label.text = "Producción: %d %s/tick" % [extractor.get_current_production(), extractor.selected_resource]
	)
	vbox.add_child(slider)
	
	vbox.add_child(HSeparator.new())
	
	var buttons = HBoxContainer.new()
	vbox.add_child(buttons)
	
	var upgrade_btn = Button.new()
	if extractor.can_upgrade():
		var cost = extractor.get_upgrade_cost()
		var cost_text = "Mejorar ("
		for res in cost:
			cost_text += "%d %s" % [cost[res], res]
		cost_text += ")"
		upgrade_btn.text = cost_text
		upgrade_btn.pressed.connect(func():
			if ExtractorSystem.ref and ExtractorSystem.ref.upgrade_extractor(extractor.instance_id):
				close_current_popup()
				show_extractor_management_popup(extractor)
		)
	else:
		upgrade_btn.text = "Nivel Máximo"
		upgrade_btn.disabled = true
	buttons.add_child(upgrade_btn)
	
	var demolish_btn = Button.new()
	demolish_btn.text = "Demoler"
	demolish_btn.modulate = Color(1, 0.5, 0.5)
	demolish_btn.pressed.connect(func():
		if ExtractorSystem.ref and ExtractorSystem.ref.demolish_extractor(extractor.instance_id):
			close_current_popup()
	)
	buttons.add_child(demolish_btn)
	
	var close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.pressed.connect(close_current_popup)
	buttons.add_child(close_btn)
	
	return popup

func _create_building_management_popup(building: BuildingInstance) -> Control:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(400, 400)
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	var title = Label.new()
	var template = building.get_template()
	title.text = template.get("name", "Building") + " - Nivel " + str(building.current_level + 1)
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	var desc = Label.new()
	desc.text = template.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	var consumption = building.get_current_consumption()
	if not consumption.is_empty():
		var cons_label = Label.new()
		var cons_text = "Consume: "
		for res in consumption:
			cons_text += "%d %s " % [consumption[res], res]
		cons_label.text = cons_text
		vbox.add_child(cons_label)
	
	var production = building.get_current_production()
	if not production.is_empty():
		var prod_label = Label.new()
		var prod_text = "Produce: "
		for res in production:
			prod_text += "%d %s " % [production[res], res]
		prod_label.text = prod_text
		vbox.add_child(prod_label)
	
	var workers_label = Label.new()
	workers_label.text = "Workers: %d / %d" % [building.assigned_workers, building.get_max_workers()]
	vbox.add_child(workers_label)
	
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = building.get_max_workers()
	slider.value = building.assigned_workers
	slider.step = 1
	slider.value_changed.connect(func(value):
		building.set_workers(int(value))
		workers_label.text = "Workers: %d / %d" % [int(value), building.get_max_workers()]
	)
	vbox.add_child(slider)
	
	vbox.add_child(HSeparator.new())
	
	var buttons = HBoxContainer.new()
	vbox.add_child(buttons)
	
	var upgrade_btn = Button.new()
	if building.can_upgrade():
		var cost = building.get_upgrade_cost()
		var cost_text = "Mejorar ("
		for res in cost:
			cost_text += "%d %s" % [cost[res], res]
		cost_text += ")"
		upgrade_btn.text = cost_text
		upgrade_btn.pressed.connect(func():
			if BuildingSystem.ref and BuildingSystem.ref.upgrade_building(building.instance_id):
				close_current_popup()
				show_building_popup(building)
		)
	else:
		upgrade_btn.text = "Nivel Máximo"
		upgrade_btn.disabled = true
	buttons.add_child(upgrade_btn)
	
	var demolish_btn = Button.new()
	demolish_btn.text = "Demoler"
	demolish_btn.modulate = Color(1, 0.5, 0.5)
	demolish_btn.pressed.connect(func():
		if BuildingSystem.ref and BuildingSystem.ref.demolish_building(building.instance_id):
			close_current_popup()
	)
	buttons.add_child(demolish_btn)
	
	var close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.pressed.connect(close_current_popup)
	buttons.add_child(close_btn)
	
	return popup
