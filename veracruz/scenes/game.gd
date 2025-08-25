class_name Game
extends Node

## Singleton ref
static var ref : Game 

## Data constructor
var data : Data = Data.new()

## Managers
var tick_manager : TickManager
var resource_manager : ResourceManager
var worker_manager : WorkerManager
var popup_manager : PopupManager
var extractor_config_manager : ExtractorConfigManager

func _init() -> void:
	if ref == null: 
		ref = self
	else: 
		queue_free()

func _ready() -> void:
	# Configurar UI layers
	_setup_ui_layers()
	
	# Asegurar que progression existe
	if data.progression == null:
		data.progression = DataProgression.new()
	
	# Crear managers
	tick_manager = TickManager.new()
	tick_manager.name = "TickManager"
	add_child(tick_manager)
	
	resource_manager = ResourceManager.new()
	resource_manager.name = "ResourceManager"
	add_child(resource_manager)
	
	worker_manager = WorkerManager.new()
	worker_manager.name = "WorkerManager"
	add_child(worker_manager)
	
	popup_manager = PopupManager.new()
	popup_manager.name = "PopupManager"
	add_child(popup_manager)
	
	extractor_config_manager = ExtractorConfigManager.new()
	extractor_config_manager.name = "ExtractorConfigManager"
	add_child(extractor_config_manager)
	
	# Conectar señales
	tick_manager.month_passed.connect(_on_month_passed)
	tick_manager.year_passed.connect(_on_year_passed)
	resource_manager.resource_changed.connect(_on_resource_changed)

func _setup_ui_layers() -> void:
	# UIManager en capa alta para UI global
	var ui_manager = $UIManager
	if ui_manager:
		ui_manager.layer = 100
	
	# La estructura ya está bien configurada en el editor:
	# - UI con PASS (deja pasar clicks)
	# - HBoxContainer con STOP (captura solo donde hay UI)
	# Solo aseguramos que los spacers no capturen
	
	var hbox = $UIManager/UI/HBoxContainer
	if hbox:
		for child in hbox.get_children():
			if child.name.begins_with("Spacer"):
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_month_passed() -> void:
	pass  # Sin print

func _on_year_passed() -> void:
	pass  # Sin print

func _on_resource_changed(resource_name: String, new_amount: int, old_amount: int) -> void:
	pass  # Sin print
