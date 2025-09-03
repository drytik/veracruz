class_name DataExtractor
extends Resource

static var EXTRACTORS = {
	"lumbermill": {
		"name": "Aserradero",
		"description": "Extrae madera del bosque",
		"category": "lumbermill",
		"available_resources": ["wood"],
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"production_per_worker": 1,
		"texture_path": ""
	},
	"quarry": {
		"name": "Cantera",
		"description": "Extrae minerales y piedra",
		"category": "quarry",
		"available_resources": ["clay", "stone", "silver", "gold"],
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"production_per_worker": 1,
		"texture_path": ""
	},
	"plantation": {
		"name": "Plantación",
		"description": "Cultiva diversos productos agrícolas",
		"category": "plantation",
		"available_resources": ["fruits", "corn", "cotton", "cocoa", "agave", "dyes"],
		"max_level": 10,
		"construction_cost": {"wood": 100},
		"upgrade_cost_per_level": 100,
		"upgrade_resource": "wood",
		"workers_per_level": 10,
		"production_per_worker": 1,
		"texture_path": ""
	}
}

static var DEFAULT_UNLOCKED_RESOURCES = {
	"lumbermill": ["wood"],
	"quarry": ["clay"],
	"plantation": ["fruits"]
}

static func get_extractor_data(category: String) -> Dictionary:
	return EXTRACTORS.get(category, {})

static func get_upgrade_cost(category: String, current_level: int) -> Dictionary:
	var data = get_extractor_data(category)
	if data.is_empty() or current_level >= data.max_level - 1:
		return {}
	
	var cost_per_level = data.upgrade_cost_per_level
	var resource = data.upgrade_resource
	var next_level = current_level + 1
	
	return {resource: cost_per_level * (next_level + 1)}

static func get_max_workers(category: String, level: int) -> int:
	var data = get_extractor_data(category)
	if data.is_empty():
		return 0
	
	return data.workers_per_level * (level + 1)

static func calculate_production(category: String, resource: String, level: int, workers: int) -> int:
	var data = get_extractor_data(category)
	if data.is_empty():
		return 0
	
	if resource not in data.available_resources:
		return 0
	
	var production_per_worker = data.production_per_worker
	return workers * production_per_worker

static func is_resource_unlocked(category: String, resource: String, unlocked_resources: Dictionary) -> bool:
	var category_unlocks = unlocked_resources.get(category, DEFAULT_UNLOCKED_RESOURCES.get(category, []))
	return resource in category_unlocks

static func get_available_resources_for_zone(category: String, unlocked_resources: Dictionary) -> Array:
	var data = get_extractor_data(category)
	if data.is_empty():
		return []
	
	var available = []
	var all_resources = data.available_resources
	
	for resource in all_resources:
		if is_resource_unlocked(category, resource, unlocked_resources):
			available.append(resource)
	
	return available
