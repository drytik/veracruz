class_name ExtractorPopup  # CORRECTO - No PopupManager
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
	var config = DataExtractor.get_extractor_data(zone_type)
	if config.is_empty():
		print("Warning: No config found for zone type: " + zone_type)
		return
	
	# Actualizar UI
	if title_label:
		title_label.text = config.get("name", "Extractor") + " - Nivel " + str(current_level + 1)
	
	if description_label:
		description_label.text = config.get("description", "")
	
	if resource_label:
		# Obtener el recurso actual si hay un extractor construido
		var resource_name = ""
		if ExtractorSystem.ref:
			var extractor = ExtractorSystem.ref.get_extractor_at_zone(zone_id)
			if extractor:
				resource_name = extractor.selected_resource
		
		if resource_name.is_empty():
			resource_label.text = "Sin extractor construido"
		else:
			resource_label.text = "Produce: " + resource_name
	
	# Configurar slider de workers
	var max_workers = DataExtractor.get_max_workers(zone_type, current_level)
	var current_workers = 0
	
	if WorkerManager.ref:
		current_workers = WorkerManager.ref.get_assigned_workers(zone_id)
	
	var idle_workers = 0
	if Game.ref and Game.ref.data and Game.ref.data.resources:
		idle_workers = Game.ref.data.resources.idle_workers
	
	if workers_slider:
		workers_slider.max_value = min(max_workers, current_workers + idle_workers)
		workers_slider.value = current_workers
	
	if workers_label:
		workers_label.text = "Workers: %d / %d (Disponibles: %d)" % [current_workers, max_workers, idle_workers]
	
	# Actualizar producción
	_update_production_display()
	
	# Configurar botón de upgrade
	if current_level >= 9:  # Nivel máximo 10 (0-9)
		if upgrade_button:
			upgrade_button.disabled = true
			upgrade_button.text = "Nivel Máximo"
	else:
		var upgrade_cost = DataExtractor.get_upgrade_cost(zone_type, current_level)
		if not upgrade_cost.is_empty() and upgrade_button:
			var cost_text = "Mejorar - Costo: "
			for res in upgrade_cost:
				cost_text += str(upgrade_cost[res]) + " " + res + " "
			upgrade_button.text = cost_text
			
			# Verificar si puede pagar
			if ResourceManager.ref:
				upgrade_button.disabled = not ResourceManager.ref.has_resources(upgrade_cost)

func _on_workers_changed(value: float) -> void:
	var new_workers = int(value)
	
	# Intentar asignar workers
	if WorkerManager.ref and WorkerManager.ref.assign_workers(zone_id, new_workers):
		# Actualizar display
		var max_workers = DataExtractor.get_max_workers(zone_type, current_level)
		var idle_workers = 0
		
		if Game.ref and Game.ref.data and Game.ref.data.resources:
			idle_workers = Game.ref.data.resources.idle_workers
		
		if workers_label:
			workers_label.text = "Workers: %d / %d (Disponibles: %d)" % [new_workers, max_workers, idle_workers]
		
		_update_production_display()
	else:
		# Revertir slider si no hay suficientes workers
		if WorkerManager.ref:
			workers_slider.value = WorkerManager.ref.get_assigned_workers(zone_id)

func _update_production_display() -> void:
	if not production_label:
		return
		
	# Obtener el extractor actual si existe
	if ExtractorSystem.ref:
		var extractor = ExtractorSystem.ref.get_extractor_at_zone(zone_id)
		if extractor:
			var production = extractor.get_current_production()
			production_label.text = "Producción: %d %s/tick" % [production, extractor.selected_resource]
		else:
			production_label.text = "Sin extractor construido"
	else:
		production_label.text = "Sistema no inicializado"

func _on_close_pressed() -> void:
	emit_signal("closed")
	queue_free()

func _on_upgrade_pressed() -> void:
	var upgrade_cost = DataExtractor.get_upgrade_cost(zone_type, current_level)
	
	if not upgrade_cost.is_empty() and ResourceManager.ref:
		if ResourceManager.ref.consume_resources(upgrade_cost):
			emit_signal("upgrade_requested", zone_id)
			# Actualizar nivel y refrescar UI
			current_level += 1
			setup_zone(zone_id, zone_type, current_level)

func _on_abandon_pressed() -> void:
	# Confirmar antes de abandonar
	emit_signal("abandon_requested", zone_id)
	_on_close_pressed()
