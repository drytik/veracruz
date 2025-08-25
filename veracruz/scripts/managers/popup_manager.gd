class_name PopupManager
extends CanvasLayer

static var ref : PopupManager

var current_popup : Control = null
#var extractor_popup_scene = preload("res://scenes/ui/extractor_popup.tscn")  # Lo crearemos después

func _init() -> void:
	if ref == null:
		ref = self
	else:
		queue_free()

func _ready():
	layer = 10  # Asegurar que está sobre todo

func show_extractor_popup(zone_id: String, zone_type: String, level: int = 0):
	close_current_popup()
	
	# Crear el popup (por ahora programáticamente, luego con .tscn)
	var popup = _create_extractor_popup()
	popup.setup_zone(zone_id, zone_type, level)
	
	# Centrar en pantalla
	add_child(popup)
	popup.position = (get_viewport().size - popup.size) / 2
	
	# Conectar señales
	popup.closed.connect(_on_popup_closed)
	popup.upgrade_requested.connect(_on_upgrade_requested)
	popup.abandon_requested.connect(_on_abandon_requested)
	
	current_popup = popup

func show_building_popup(building_id: String, building_type: String, level: int = 0):
	# TODO: Implementar cuando hagamos BuildingPopup
	pass

func close_current_popup():
	if current_popup:
		current_popup.queue_free()
		current_popup = null

func _on_popup_closed():
	current_popup = null

func _on_upgrade_requested(zone_id: String):
	# TODO: Implementar lógica de upgrade
	print("Upgrade requested for: " + zone_id)
	close_current_popup()

func _on_abandon_requested(zone_id: String):
	# Liberar workers
	WorkerManager.ref.free_workers(zone_id)
	# TODO: Marcar zona como abandonada
	print("Abandon zone: " + zone_id)
	close_current_popup()

## Crear popup programáticamente (temporal hasta hacer el .tscn)
func _create_extractor_popup() -> ExtractorPopup:
	var popup = ExtractorPopup.new()
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
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
	
	return popup
