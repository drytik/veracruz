class_name BaseExtractor
extends Node2D

@export var extractor_id : String = ""
@export var extractor_type : String = "lumbermill"
@export var zone_area : ConstructionArea
@export var current_level : int = 0

var sprite : Sprite2D
var is_active : bool = false
var months_since_production : int = 0
var production_cycle : int = 1  # Meses entre producciones (1 = mensual)

# YA NO NECESITAMOS extractor_configs aquí - usaremos ExtractorConfigManager

func _ready() -> void:
	# Generar ID único si no tiene
	if extractor_id.is_empty():
		extractor_id = extractor_type + "_" + str(get_instance_id())
	
	# Registrarse para recibir ticks
	add_to_group("tick_receivers")
	add_to_group("extractors")
	
	# Conectar señales del TickManager
	if TickManager.ref:
		TickManager.ref.month_passed.connect(_on_month_passed)
	
	# Crear sprite visual
	_create_visual()
	
	# Obtener configuración
	var config = ExtractorConfigManager.ref.get_config(extractor_type)
	if not config.is_empty():
		production_cycle = config.get("production_cycle", 1)
	
	# Registrar en DataProgression para save/load
	_register_in_progression()

func _create_visual() -> void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	_update_visual()

func _update_visual() -> void:
	var config = ExtractorConfigManager.ref.get_config(extractor_type)
	if config.is_empty():
		return
		
	# Por ahora usar placeholder siempre ya que no tenemos texturas
	_create_placeholder_visual()

func _create_placeholder_visual() -> void:
	# Crear un ColorRect como placeholder
	var placeholder = ColorRect.new()
	placeholder.size = Vector2(100, 100)
	placeholder.position = Vector2(-50, -50)
	placeholder.color = Color(0.5, 0.3, 0.1, 0.8)  # Marrón
	
	# Añadir label con el tipo
	var label = Label.new()
	label.text = extractor_type.capitalize()
	label.position = Vector2(-40, -10)
	placeholder.add_child(label)
	
	sprite.add_child(placeholder)

func _register_in_progression() -> void:
	# Buscar si ya existe en progression
	var found = false
	for data in Game.ref.data.progression.extractors_data:
		if data.get("extractor_id") == extractor_id:
			found = true
			current_level = data.get("level", 0)
			break
	
	# Si no existe, añadir
	if not found:
		var data = {
			"extractor_id": extractor_id,
			"type": extractor_type,
			"level": current_level,
			"position": global_position
		}
		Game.ref.data.progression.extractors_data.append(data)

func activate() -> void:
	is_active = true
	visible = true

func deactivate() -> void:
	is_active = false
	visible = false
	# Liberar workers si hay
	WorkerManager.ref.free_workers(extractor_id)

func _on_month_passed() -> void:
	if not is_active:
		return
		
	months_since_production += 1
	
	# Verificar si toca producir
	if months_since_production >= production_cycle:
		months_since_production = 0
		_produce_resources()

func _produce_resources() -> void:
	var workers = WorkerManager.ref.get_assigned_workers(extractor_id)
	if workers == 0:
		return
	
	var config = ExtractorConfigManager.ref.get_config(extractor_type)
	if config.is_empty():
		return
	
	# Calcular producción basada en workers
	var max_workers = config.max_workers[current_level]
	var base_production = config.base_production[current_level]
	
	# Producción proporcional a workers asignados
	var efficiency = float(workers) / float(max_workers)
	var actual_production = int(base_production * efficiency)
	
	# Añadir recurso
	var resource_type = config.resource
	
	# Si es plantación, verificar recurso específico de la zona
	if extractor_type == "plantation" and zone_area:
		var zone_resources = zone_area.available_resources
		if zone_resources.size() > 0:
			resource_type = zone_resources[0]
	
	ResourceManager.ref.add_resource(resource_type, actual_production)
	
	# Crear notificación visual (opcional)
	_show_production_popup(actual_production, resource_type)

func _show_production_popup(amount: int, resource: String) -> void:
	# Crear un label temporal que muestre la producción
	var popup = Label.new()
	popup.text = "+%d %s" % [amount, resource]
	popup.add_theme_color_override("font_color", Color.GREEN)
	popup.add_theme_font_size_override("font_size", 16)
	popup.position = Vector2(0, -50)
	add_child(popup)
	
	# Animar hacia arriba y desvanecer
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", -100, 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(popup.queue_free)

func upgrade() -> bool:
	if current_level >= 3:  # Max nivel 4 (0-3)
		return false
	
	var config = ExtractorConfigManager.ref.get_config(extractor_type)
	if config.is_empty():
		return false
	
	# Verificar costos (definidos en ExtractorPopup por ahora)
	# TODO: Mover costos aquí o a un UpgradeManager
	
	current_level += 1
	_update_visual()
	
	# Actualizar en progression
	for data in Game.ref.data.progression.extractors_data:
		if data.get("extractor_id") == extractor_id:
			data["level"] = current_level
			break
	
	return true

func get_info() -> Dictionary:
	var config = ExtractorConfigManager.ref.get_config(extractor_type)
	var workers = WorkerManager.ref.get_assigned_workers(extractor_id)
	var max_workers = config.get("max_workers", [10])[current_level]
	var base_production = config.get("base_production", [10])[current_level]
	
	var efficiency = 0.0
	if max_workers > 0:
		efficiency = float(workers) / float(max_workers)
	
	return {
		"id": extractor_id,
		"type": extractor_type,
		"name": config.get("name", "Unknown"),
		"level": current_level,
		"workers": workers,
		"max_workers": max_workers,
		"efficiency": efficiency,
		"production_per_cycle": int(base_production * efficiency),
		"production_cycle": production_cycle,
		"resource": config.get("resource", "unknown")
	}
