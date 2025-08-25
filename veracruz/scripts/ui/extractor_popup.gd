class_name ExtractorPopup
extends PanelContainer

signal closed
signal workers_changed(zone_id: String, workers: int)
signal upgrade_requested(zone_id: String)
signal abandon_requested(zone_id: String)

@onready var title_label : Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var close_button : Button = $MarginContainer/VBoxContainer/Header/CloseButton
@onready var description_label : Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var resource_label : Label = $MarginContainer/VBoxContainer/ResourceLabel
@onready var workers_label : Label = $MarginContainer/VBoxContainer/WorkersSection/WorkersLabel
@onready var workers_slider : HSlider = $MarginContainer/VBoxContainer/WorkersSection/WorkersSlider
@onready var production_label : Label = $MarginContainer/VBoxContainer/ProductionLabel
@onready var upgrade_button : Button = $MarginContainer/VBoxContainer/ButtonsContainer/UpgradeButton
@onready var abandon_button : Button = $MarginContainer/VBoxContainer/ButtonsContainer/AbandonButton

var current_zone_id : String = ""
var current_zone_type : String = ""
var current_level : int = 0
var max_workers : int = 0

## Configuraciones por tipo de extractor
var extractor_configs = {
	"lumbermill": {
		"name": "Aserradero",
		"description": "Produce madera de los bosques cercanos",
		"resource": "wood",
		"resource_name": "Madera",
		"max_workers": [10, 20, 30, 40],  # Por nivel
		"base_production": [10, 20, 35, 50],  # Por nivel con max workers
		"upgrade_cost": [
			{"wood": 50, "tools": 5},
			{"wood": 100, "stone": 50, "tools": 10},
			{"wood": 200, "stone": 100, "tools": 20}
		]
	},
	"quarry": {
		"name": "Cantera",
		"description": "Extrae piedra y minerales",
		"resource": "stone",  # Puede variar según la zona
		"resource_name": "Piedra",
		"max_workers": [15, 25, 35, 45],
		"base_production": [8, 16, 28, 40],
		"upgrade_cost": [
			{"wood": 30, "tools": 8},
			{"wood": 80, "stone": 60, "tools": 15},
			{"wood": 150, "stone": 120, "tools": 25}
		]
	}
}

func _ready():
	# Conectar botones
	close_button.pressed.connect(_on_close_pressed)
	workers_slider.value_changed.connect(_on_workers_changed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	abandon_button.pressed.connect(_on_abandon_pressed)
	
	# Centrar en pantalla
	custom_minimum_size = Vector2(400, 500)
	
func setup_zone(zone_id: String, zone_type: String, level: int = 0):
	current_zone_id = zone_id
	current_zone_type = zone_type
	current_level = level
	
	var config = extractor_configs.get(zone_type, {})
	if config.is_empty():
		push_error("Unknown zone type: " + zone_type)
		return
		
	# Configurar UI
	title_label.text = config.name + " - Nivel " + str(level + 1)
	description_label.text = config.description
	resource_label.text = "Produce: " + config.resource_name
	
	# Configurar workers
	max_workers = config.max_workers[level]
	var current_workers = WorkerManager.ref.get_assigned_workers(zone_id)
	workers_slider.max_value = max_workers
	workers_slider.value = current_workers
	_update_workers_label(current_workers)
	
	# Actualizar producción
	_update_production_label(current_workers)
	
	# Configurar botón upgrade
	if level < 3:  # Max nivel 4
		var upgrade_cost = config.upgrade_cost[level]
		var cost_text = "Mejorar - Costo: "
		for resource in upgrade_cost:
			cost_text += str(upgrade_cost[resource]) + " " + resource + " "
		upgrade_button.text = cost_text
		upgrade_button.disabled = not ResourceManager.ref.has_resources(upgrade_cost)
	else:
		upgrade_button.text = "Nivel Máximo"
		upgrade_button.disabled = true

func _update_workers_label(workers: int):
	workers_label.text = "Trabajadores: %d/%d" % [workers, max_workers]
	
	var idle = Game.ref.data.resources.idle_workers
	if workers < max_workers:
		workers_label.text += " (Disponibles: %d)" % idle

func _update_production_label(workers: int):
	var config = extractor_configs.get(current_zone_type, {})
	if config.is_empty():
		return
		
	var max_production = config.base_production[current_level]
	var actual_production = 0
	if max_workers > 0:
		actual_production = int(max_production * float(workers) / float(max_workers))
	
	production_label.text = "Producción: %d %s/mes" % [actual_production, config.resource_name]

func _on_close_pressed():
	emit_signal("closed")
	queue_free()

func _on_workers_changed(value: float):
	var new_workers = int(value)
	if WorkerManager.ref.assign_workers(current_zone_id, new_workers):
		_update_workers_label(new_workers)
		_update_production_label(new_workers)
		emit_signal("workers_changed", current_zone_id, new_workers)
	else:
		# Revertir slider si no hay suficientes workers
		workers_slider.value = WorkerManager.ref.get_assigned_workers(current_zone_id)

func _on_upgrade_pressed():
	emit_signal("upgrade_requested", current_zone_id)

func _on_abandon_pressed():
	emit_signal("abandon_requested", current_zone_id)
