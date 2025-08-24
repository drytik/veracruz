class_name Game
extends Node

## Singleton ref
static var ref : Game 

## Data constructor
var data : Data = Data.new()

## Managers
var tick_manager : TickManager
#var resource_manager : ResourceManager
#var worker_manager : WorkerManager

func _init() -> void:
	if ref == null: 
		ref = self
	else: 
		queue_free()

func _ready() -> void:
	# Crear managers
	tick_manager = TickManager.new()
	tick_manager.name = "TickManager"
	add_child(tick_manager)
	
	# Por ahora comentados hasta que los creemos
	#resource_manager = ResourceManager.new()
	#resource_manager.name = "ResourceManager"
	#add_child(resource_manager)
	
	#worker_manager = WorkerManager.new()
	#worker_manager.name = "WorkerManager"
	#add_child(worker_manager)
	
	# Conectar señales para debug
	tick_manager.month_passed.connect(_on_month_passed)
	tick_manager.year_passed.connect(_on_year_passed)
	
	print("=== GAME STARTED ===")
	print("Date: %s" % tick_manager.get_date_string())
	print("Initial resources: Wood=%d, Stone=%d, Tools=%d, Piece of 8=%d" % [
		data.resources.wood,
		data.resources.stone, 
		data.resources.tools,
		data.resources.piece_of_8
	])

func _on_month_passed() -> void:
	print("Month passed: %s" % tick_manager.get_date_string())

func _on_year_passed() -> void:
	print("=== YEAR %d ENDED ===" % (tick_manager.current_year - 1))
