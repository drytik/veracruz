class_name ExtractorPopup
extends PanelContainer

signal closed
signal upgrade_requested(zone_id: String)
signal abandon_requested(zone_id: String)

var zone_id : String = ""
var zone_type : String = ""
var current_level : int = 0

@onready var title_label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var close_button = $MarginContainer/VBoxContainer/Header/CloseButton
@onready var description_label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var resource_label = $MarginContainer/VBoxContainer/ResourceLabel
@onready var workers_label = $MarginContainer/VBoxContainer/WorkersSection/WorkersLabel
@onready var workers_slider = $MarginContainer/VBoxContainer/WorkersSection/WorkersSlider
@onready var production_label = $MarginContainer/VBoxContainer/ProductionLabel
@onready var upgrade_button = $MarginContainer/VBoxContainer/ButtonsContainer/UpgradeButton
@onready var abandon_button = $MarginContainer/VBoxContainer/ButtonsContainer/AbandonButton

func _ready() -> void:
	# Conectar botones
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if abandon_button:
		abandon_button.pressed.connect(_on_abandon_pressed)
	if workers_slider:
		workers_slider.value_changed.connect(_on_workers_changed)

func setup_zone(p_zone_id: String, p_zone_type: String, p_level: int = 0) -> void:
	zone_id = p_zone_id
	zone_type = p_zone_type
	current_level = p_level
	
	# Obtener configuración del extractor
	var config = ExtractorConfigManager.ref.get_config(zone_type)
	if config.is_empty():
		print("Warning: No config found for zone type: " + zone_type)
		return
	
	# Actualizar UI
	if title_label:
		title_label.text = config.get("name", "Extractor") + " - Nivel " + str(current_level + 1)
	
	if description_label:
		description_label.text = config.get("description", "")
	
	if resource_label:
		resource_label.text = "Produce: " + config.get("resource_display_name", "")
	
	# Configurar slider de workers
	var max_workers = config.get("max_workers", [10, 20, 30, 40])[current_level]
	var current_workers = WorkerManager.ref.get_assigned_workers(zone_id)
	var idle_workers = Game.ref.data.resources.idle_workers
	
	if workers_slider:
		workers_slider.max_value = min(max_workers, current_workers + idle_workers)
		workers_slider.value = current_workers
	
	if workers_label:
		workers_label.text = "Workers: %d / %d (Disponibles: %d)" % [current_workers, max_workers, idle_workers]
	
	# Actualizar producción
	_update_production_display()
	
	# Configurar botón de upgrade
	if current_level >= 3:
		if upgrade_button:
			upgrade_button.disabled = true
			upgrade_button.text = "Nivel Máximo"
	else:
		var upgrade_costs = config.get("upgrade_cost", [])
		if upgrade_costs.size() > current_level:
			var cost = upgrade_costs[current_level]
			if upgrade_button:
				upgrade_button.text = "Mejorar - Costo: "
				for res in cost:
					upgrade_button.text += str(cost[res]) + " " + res + " "
				
				# Verificar si puede pagar
				upgrade_button.disabled = not ResourceManager.ref.has_resources(cost)

func _on_workers_changed(value: float) -> void:
	var new_workers = int(value)
	
	# Intentar asignar workers
	if WorkerManager.ref.assign_workers(zone_id, new_workers):
		# Actualizar display
		var config = ExtractorConfigManager.ref.get_config(zone_type)
		var max_workers = config.get("max_workers", [10])[current_level]
		var idle_workers = Game.ref.data.resources.idle_workers
		
		if workers_label:
			workers_label.text = "Workers: %d / %d (Disponibles: %d)" % [new_workers, max_workers, idle_workers]
		
		_update_production_display()
	else:
		# Revertir slider si no hay suficientes workers
		workers_slider.value = WorkerManager.ref.get_assigned_workers(zone_id)

func _update_production_display() -> void:
	var config = ExtractorConfigManager.ref.get_config(zone_type)
	if config.is_empty():
		return
	
	var workers = WorkerManager.ref.get_assigned_workers(zone_id)
	var max_workers = config.get("max_workers", [10])[current_level]
	var base_production = config.get("base_production", [10])[current_level]
	var production_cycle = config.get("production_cycle", 1)
	
	var efficiency = 0.0
	if max_workers > 0:
		efficiency = float(workers) / float(max_workers)
	
	var actual_production = int(base_production * efficiency)
	
	if production_label:
		var cycle_text = "mensual" if production_cycle == 1 else "cada %d meses" % production_cycle
		production_label.text = "Producción %s: %d (Eficiencia: %d%%)" % [
			cycle_text, 
			actual_production, 
			int(efficiency * 100)
		]

func _on_close_pressed() -> void:
	emit_signal("closed")
	queue_free()

func _on_upgrade_pressed() -> void:
	var config = ExtractorConfigManager.ref.get_config(zone_type)
	var upgrade_costs = config.get("upgrade_cost", [])
	
	if current_level < upgrade_costs.size():
		var cost = upgrade_costs[current_level]
		if ResourceManager.ref.consume_resources(cost):
			emit_signal("upgrade_requested", zone_id)
			# Actualizar nivel y refrescar UI
			current_level += 1
			setup_zone(zone_id, zone_type, current_level)

func _on_abandon_pressed() -> void:
	# Confirmar antes de abandonar
	emit_signal("abandon_requested", zone_id)
	_on_close_pressed()
