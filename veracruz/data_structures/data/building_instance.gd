class_name BuildingInstance
extends Resource

@export var instance_id: String = ""
@export var building_type: String = ""
@export var current_level: int = 0
@export var assigned_workers: int = 0
@export var slot_id: String = ""
@export var position: Vector2 = Vector2.ZERO
@export var is_active: bool = true
@export var custom_data: Dictionary = {}

func _init(p_type: String = "", p_slot: String = "") -> void:
	if not p_type.is_empty():
		building_type = p_type
		slot_id = p_slot
		instance_id = "%s_%s_%d" % [building_type, p_slot, Time.get_ticks_msec()]

func get_template() -> Dictionary:
	return DataBuilding.get_building_data(building_type)

func get_max_workers() -> int:
	return DataBuilding.get_max_workers(building_type, current_level)

func get_current_production() -> Dictionary:
	if not is_active or assigned_workers == 0:
		return {}
	
	return DataBuilding.calculate_production(building_type, current_level, assigned_workers)

func get_current_consumption() -> Dictionary:
	if not is_active or assigned_workers == 0:
		return {}
	
	return DataBuilding.calculate_consumption(building_type, current_level, assigned_workers)

func can_produce() -> bool:
	if not is_active or assigned_workers == 0:
		return false
	
	var consumption = get_current_consumption()
	
	if ResourceManager.ref and not consumption.is_empty():
		for resource in consumption:
			var required = consumption[resource]
			var available = ResourceManager.ref.get_resource(resource)
			if available < required:
				return false
	
	return true

func process_production() -> bool:
	if not can_produce():
		return false
	
	var consumption = get_current_consumption()
	if ResourceManager.ref and not consumption.is_empty():
		for resource in consumption:
			ResourceManager.ref.consume_resource(resource, consumption[resource])
	
	var production = get_current_production()
	if ResourceManager.ref and not production.is_empty():
		for resource in production:
			ResourceManager.ref.add_resource(resource, production[resource])
	
	return true

func can_upgrade() -> bool:
	var template = get_template()
	return current_level < template.get("max_level", 10) - 1

func get_upgrade_cost() -> Dictionary:
	return DataBuilding.get_upgrade_cost(building_type, current_level)

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
