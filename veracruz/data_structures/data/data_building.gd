class_name DataBuilding
extends Resource

# Templates de TODOS los edificios - NO CAMBIAN
static var BUILDINGS = {
	"port": {
		"name": "Puerto",
		"description": "Permite el comercio marítimo",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {},
		"produced_materials": {"piece_of_8": 5},
		"texture_path": "res://assets/buildings/PuertoAstillero_Lvl_1.png"
	},
	"tavern": {
		"name": "Taberna",
		"description": "Mejora la felicidad de los colonos",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {"fruits": 2},
		"produced_materials": {"happiness": 5},
		"texture_path": "res://assets/buildings/Taberna_Lvl_1.png"
	},
	"warehouse": {
		"name": "Almacén",
		"description": "Aumenta la capacidad de almacenamiento",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {},
		"produced_materials": {},
		"special_effect": "storage_bonus",
		"texture_path": ""
	},
	"carpentry": {
		"name": "Carpintería",
		"description": "Transforma madera en tablones",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {"wood": 2},
		"produced_materials": {"planks": 1},
		"texture_path": ""
	},
	"forge": {
		"name": "Forja",
		"description": "Produce herramientas",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {"iron": 1, "wood": 1},
		"produced_materials": {"tools": 1},
		"texture_path": ""
	},
	"mill": {
		"name": "Molino",
		"description": "Procesa maíz en harina",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {"corn": 2},
		"produced_materials": {"flour": 1},
		"texture_path": ""
	},
	"market": {
		"name": "Mercado",
		"description": "Centro de comercio local",
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"required_materials": {},
		"produced_materials": {"piece_of_8": 2},
		"texture_path": ""
	},
	"church": {
		"name": "Iglesia",
		"description": "Centro espiritual de la colonia",
		"max_level": 10,
		"construction_cost": {"wood": 100, "stone": 50},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "stone",
		"workers_per_level": 10,
		"required_materials": {},
		"produced_materials": {"happiness": 3},
		"texture_path": ""
	}
}

static func get_building_data(type: String) -> Dictionary:
	return BUILDINGS.get(type, {})

static func get_upgrade_cost(type: String, current_level: int) -> Dictionary:
	var data = get_building_data(type)
	if data.is_empty() or current_level >= data.max_level - 1:
		return {}
	
	var cost_per_level = data.upgrade_cost_per_level
	var resource = data.upgrade_resource
	var next_level = current_level + 1
	
	return {resource: cost_per_level * (next_level + 1)}

static func get_max_workers(type: String, level: int) -> int:
	var data = get_building_data(type)
	if data.is_empty():
		return 0
	
	return data.workers_per_level * (level + 1)

static func calculate_production(type: String, level: int, workers: int) -> Dictionary:
	var data = get_building_data(type)
	if data.is_empty():
		return {}
	
	var max_workers = get_max_workers(type, level)
	if max_workers == 0:
		return {}
	
	var efficiency = float(workers) / float(max_workers)
	var result = {}
	
	for resource in data.produced_materials:
		var base_amount = data.produced_materials[resource]
		result[resource] = int(base_amount * efficiency)
	
	return result

static func calculate_consumption(type: String, level: int, workers: int) -> Dictionary:
	var data = get_building_data(type)
	if data.is_empty():
		return {}
	
	var max_workers = get_max_workers(type, level)
	if max_workers == 0 or workers == 0:
		return {}
	
	var efficiency = float(workers) / float(max_workers)
	var result = {}
	
	for resource in data.required_materials:
		var base_amount = data.required_materials[resource]
		result[resource] = int(ceil(base_amount * efficiency))
	
	return result
