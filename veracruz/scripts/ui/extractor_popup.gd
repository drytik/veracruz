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
		"resource_display_name": "Madera",  # Cambiado
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
		"resource_display_name": "Piedra",  # Cambiado
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
		"resource_display_name": "Maíz",  # Cambiado
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
	# NO llamar _get_node_references aquí porque aún no está en el árbol
	# Se llamará desde setup_zone después de ser añadido
	
	# Centrar en pantalla
	custom_minimum_size = Vector2(400, 500)

func _get_node_references():
	# NO usar await aquí
	# Buscar los nodos por su path correcto
	var base_path = "MarginContainer/VBoxContainer/"
	
	# Intentar obtener las referencias
	title_label = get_node_or_null(base_path + "Header/TitleLabel")
	close_button = get_node_or_null(base_path + "Header/CloseButton")
	description_label = get_node_or_null(base_path + "DescriptionLabel")
	resource_label = get_node_or_null(base_path + "ResourceLabel")
	workers_label = get_node_or_null(base_path + "WorkersSection/WorkersLabel")
	workers_slider = get_node_or_null(base_path + "WorkersSection/WorkersSlider")
	production_label = get_node_or_null(base_path + "ProductionLabel")
	upgrade_button = get_node_or_null(base_path + "ButtonsContainer/UpgradeButton")
	abandon_button = get_node_or_null(base_path + "ButtonsContainer/AbandonButton")
	
	# Conectar señales si los nodos existen
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if workers_slider:
		workers_slider.value_changed.connect(_on_workers_changed)
		print("Slider connected successfully")
	else:
		print("ERROR: Slider not found")
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if abandon_button:
		abandon_button.pressed.connect(_on_abandon_pressed)
	
func setup_zone(zone_id: String, zone_type: String, level: int = 0):
	current_zone_id = zone_id
	current_zone_type = zone_type
	current_level = level
	
	# Obtener referencias DESPUÉS de ser añadido al árbol
	call_deferred("_setup_zone_deferred", zone_id, zone_type, level)

func _setup_zone_deferred(zone_id: String, zone_type: String, level: int):
	# Ahora sí obtener las referencias
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
		resource_label.text = "Produce: " + config.resource_display_name  # Cambiado
	
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
	
	production_label.text = "Producción: %d %s/mes" % [actual_production, config.resource_display_name]  # Cambiado

func _on_close_pressed():
	emit_signal("closed")
	queue_free()

func _on_workers_changed(value: float):
	print("Slider changed to: %f" % value)
	var new_workers = int(value)
	
	# Si es la primera vez que se asignan workers, crear el extractor
	if new_workers > 0:
		_ensure_extractor_exists()
	
	if WorkerManager.ref.assign_workers(current_zone_id, new_workers):
		print("Workers assigned: %d" % new_workers)
		_update_workers_label(new_workers)
		_update_production_label(new_workers)
		emit_signal("workers_changed", current_zone_id, new_workers)
	else:
		print("Failed to assign workers")
		# Revertir slider si no hay suficientes workers
		if workers_slider:
			workers_slider.value = WorkerManager.ref.get_assigned_workers(current_zone_id)

func _ensure_extractor_exists():
	# Verificar si ya existe el extractor
	var extractors = get_tree().get_nodes_in_group("extractors")
	for extractor in extractors:
		if extractor.extractor_id == current_zone_id:
			return  # Ya existe
	
	# Crear nuevo extractor
	var extractor = BaseExtractor.new()
	extractor.extractor_id = current_zone_id
	extractor.extractor_type = current_zone_type
	extractor.current_level = current_level
	
	# Encontrar la zona para obtener la posición
	var zones = get_tree().get_nodes_in_group("world_extractor_zones")
	for zone in zones:
		if zone.zone_id == current_zone_id:
			extractor.position = zone.global_position
			extractor.zone_area = zone
			break
	
	# Añadir al WorldScene
	var world_scene = get_node_or_null("/root/Game/SceneManager/WorldScene")
	if world_scene:
		world_scene.add_child(extractor)
		extractor.activate()
		print("Extractor created: %s at %s" % [current_zone_id, extractor.position])

func _on_upgrade_pressed():
	emit_signal("upgrade_requested", current_zone_id)

func _on_abandon_pressed():
	emit_signal("abandon_requested", current_zone_id)
