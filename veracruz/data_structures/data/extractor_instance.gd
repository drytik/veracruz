class_name ExtractorInstance
extends Resource

@export var instance_id: String = ""
@export var extractor_category: String = ""
@export var selected_resource: String = ""
@export var current_level: int = 0
@export var assigned_workers: int = 0
@export var zone_id: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var is_active: bool = true

func _init(p_category: String = "", p_resource: String = "", p_zone: String = "") -> void:
	if not p_category.is_empty():
		extractor_category = p_category
		selected_resource = p_resource
		zone_id = p_zone
		instance_id = "%s_%s_%s_%d" % [extractor_category, selected_resource, p_zone, Time.get_ticks_msec()]

func get_template() -> Dictionary:
	return DataExtractor.get_extractor_data(extractor_category)

func get_max_workers() -> int:
	return DataExtractor.get_max_workers(extractor_category, current_level)

func get_current_production() -> int:
	if not is_active or assigned_workers == 0:
		return 0
	
	return DataExtractor.calculate_production(extractor_category, selected_resource, current_level, assigned_workers)

func process_production() -> bool:
	if not is_active or assigned_workers == 0:
		return false
	
	var production = get_current_production()
	
	if production > 0 and ResourceManager.ref:
		ResourceManager.ref.add_resource(selected_resource, production)
		return true
	
	return false

func can_upgrade() -> bool:
	var template = get_template()
	return current_level < template.get("max_level", 10) - 1

func get_upgrade_cost() -> Dictionary:
	return DataExtractor.get_upgrade_cost(extractor_category, current_level)

func upgrade() -> bool:
	if not can_upgrade():
		return false
	
	var cost = get_upgrade_cost()
	if ResourceManager.ref and ResourceManager.ref.consume_resources(cost):
		current_level += 1
		return true
	
	return false

func set_workers(count: int) -> bool:
	var max_workers = get_max_workers()
	count = clamp(count, 0, max_workers)
	
	if WorkerManager.ref:
		if WorkerManager.ref.assign_workers(instance_id, count):
			assigned_workers = count
			return true
	
	return false

func demolish() -> void:
	if WorkerManager.ref:
		WorkerManager.ref.free_workers(instance_id)
	
	assigned_workers = 0
	is_active = false

func get_display_name() -> String:
	var template = get_template()
	return "%s (%s)" % [template.get("name", "Extractor"), selected_resource]

func get_info() -> Dictionary:
	return {
		"id": instance_id,
		"category": extractor_category,
		"resource": selected_resource,
		"level": current_level,
		"workers": assigned_workers,
		"max_workers": get_max_workers(),
		"production": get_current_production(),
		"is_active": is_active
	}
