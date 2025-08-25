class_name ExtractorPopup
extends PanelContainer

signal closed
signal workers_changed(zone_id: String, workers: int)
signal upgrade_requested(zone_id: String)
signal abandon_requested(zone_id: String)

# NO usar @onready porque creamos los nodos programáticamente
var title_label : Label
var close_button : Button
var description_label : Label
var resource_label : Label
var workers_label : Label
var workers_slider : HSlider
var production_label : Label
var upgrade_button : Button
var abandon_button : Button

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
	},
	"plantation": {
		"name": "Plantación",
		"description": "Cultiva productos agrícolas",
		"resource": "corn",  # Puede variar
		"resource_name": "Maíz",
		"max_workers": [20, 30, 40, 50],
		"base_production": [15, 30, 45, 65],
		"upgrade_cost": [
			{"wood": 40, "tools": 3},
			{"wood": 90, "stone": 40, "tools": 8},
			{"wood": 180, "stone": 90, "tools": 15}
		]
	}
}

func _ready():
	# Obtener referencias a los nodos creados
	_get_node_references()
	
	# Conectar botones si existen
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if workers_slider:
		workers_slider.value_changed.connect(_on_workers_changed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if abandon_button:
		abandon_button.pressed.connect(_on_abandon_pressed)
	
	# Centrar en pantalla
	custom_minimum_size = Vector2(400, 500)

func _get_node_references():
	# Buscar los nodos por su path
	var base_path = "MarginContainer/VBoxContainer/"
	
	# Intentar obtener las referencias
	if has_node(base_path + "Header/TitleLabel"):
		title_label = get_node(base_path + "Header/TitleLabel")
	if has_node(base_path + "Header/CloseButton"):
		close_button = get_node(base_path + "Header/CloseButton")
	if has_node(base_path + "DescriptionLabel"):
		description_label = get_node(base_path + "DescriptionLabel")
	if has_node(base_path + "ResourceLabel"):
		resource_label = get_node(base_path + "ResourceLabel")
	if has_node(base_path + "WorkersSection/WorkersLabel"):
		workers_label = get_node(base_path + "WorkersSection/WorkersLabel")
	if has_node(base_path + "WorkersSection/WorkersSlider"):
		workers_slider = get_node(base_path + "WorkersSection/WorkersSlider")
	if has_node(base_path + "ProductionLabel"):
		production_label = get_node(base_path + "ProductionLabel")
	if has_node(base_path + "ButtonsContainer/UpgradeButton"):
		upgrade_button = get_node(base_path + "ButtonsContainer/UpgradeButton")
	if has_node(base_path + "ButtonsContainer/AbandonButton"):
		abandon_button = get_node(base_path + "ButtonsContainer/AbandonButton")
	
func setup_zone(zone_id: String, zone_type: String, level: int = 0):
	current_zone_id = zone_id
	current_zone_type = zone_type
	current_level = level
	
	# Asegurarse de tener las referencias
	if not title_label:
		_get_node_references()
	
	var config = extractor_configs.get(zone_type, {})
	if config.is_empty():
		push_error("Unknown zone type: " + zone_type)
		return
		
	# Configurar UI
	if title_label:
		title_label.text = config.name + " - Nivel " + str(level + 1)
	if description_label:
		description_label.text = config.description
	if resource_label:
		resource_label.text = "Produce: " + config.resource_name
	
	# Configurar workers
	max_workers = config.max_workers[level]
	var current_workers = WorkerManager.ref.get_assigned_workers(zone_id)
	
	if workers_slider:
		workers_slider.max_value = max_workers
		workers_slider.value = current_workers
	
	_update_workers_label(current_workers)
	_update_production_label(current_workers)
	
	# Configurar botón upgrade
	if upgrade_button:
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
	if not workers_label:
		return
		
	workers_label.text = "Trabajadores: %d/%d" % [workers, max_workers]
	
	var idle = Game.ref.data.resources.idle_workers
	if workers < max_workers:
		workers_label.text += " (Disponibles: %d)" % idle

func _update_production_label(workers: int):
	if not production_label:
		return
		
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
		if workers_slider:
			workers_slider.value = WorkerManager.ref.get_assigned_workers(current_zone_id)

func _on_upgrade_pressed():
	emit_signal("upgrade_requested", current_zone_id)

func _on_abandon_pressed():
	emit_signal("abandon_requested", current_zone_id)
