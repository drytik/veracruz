class_name DataExtractorConfig
extends Resource

@export var name : String = "Extractor"
@export var description : String = ""
@export var resource_produced : String = "wood"
@export var resource_display_name : String = "Wood"  # Cambiado de resource_name

@export_group("Production")
@export var max_workers : Array[int] = [10, 20, 30, 40]  # Por nivel
@export var base_production : Array[int] = [10, 20, 35, 50]  # Por nivel con max workers
@export var production_cycle : int = 1  # Meses entre producciones

@export_group("Upgrade Costs")
@export var upgrade_costs : Array[Dictionary] = [
	{"wood": 50, "tools": 5},
	{"wood": 100, "stone": 50, "tools": 10},
	{"wood": 200, "stone": 100, "tools": 20}
]

@export_group("Visuals")
@export var texture_paths : Array[String] = []
@export var placeholder_color : Color = Color(0.5, 0.3, 0.1, 0.8)
