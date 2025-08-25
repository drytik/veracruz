class_name ExtractorConfigManager
extends Node

static var ref : ExtractorConfigManager

# Diccionario temporal hasta que crees los archivos .tres
# Después esto se cargará desde Resources
var configs : Dictionary = {}

func _init() -> void:
	if ref == null:
		ref = self
	else:
		queue_free()

func _ready() -> void:
	_load_configs()

func _load_configs() -> void:
	# TEMPORAL: Configuraciones hardcodeadas
	# TODO: Reemplazar con load("res://data_structures/configs/extractors/lumbermill.tres")
	
	configs["lumbermill"] = {
		"name": "Aserradero",
		"description": "Produce madera de los bosques cercanos",
		"resource": "wood",
		"resource_display_name": "Madera",
		"max_workers": [10, 20, 30, 40],
		"base_production": [10, 20, 35, 50],
		"production_cycle": 1,
		"upgrade_cost": [
			{"wood": 50, "tools": 5},
			{"wood": 100, "stone": 50, "tools": 10},
			{"wood": 200, "stone": 100, "tools": 20}
		]
	}
	
	configs["quarry"] = {
		"name": "Cantera",
		"description": "Extrae piedra y minerales",
		"resource": "stone",
		"resource_display_name": "Piedra",
		"max_workers": [15, 25, 35, 45],
		"base_production": [8, 16, 28, 40],
		"production_cycle": 1,
		"upgrade_cost": [
			{"wood": 30, "tools": 8},
			{"wood": 80, "stone": 60, "tools": 15},
			{"wood": 150, "stone": 120, "tools": 25}
		]
	}
	
	configs["plantation"] = {
		"name": "Plantación",
		"description": "Cultiva productos agrícolas",
		"resource": "corn",
		"resource_display_name": "Maíz",
		"max_workers": [20, 30, 40, 50],
		"base_production": [30, 60, 90, 130],
		"production_cycle": 6,
		"upgrade_cost": [
			{"wood": 40, "tools": 3},
			{"wood": 90, "stone": 40, "tools": 8},
			{"wood": 180, "stone": 90, "tools": 15}
		]
	}

func get_config(extractor_type: String) -> Dictionary:
	return configs.get(extractor_type, {})
