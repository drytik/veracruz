class_name BuildingSystem
extends Node

static var ref : BuildingSystem

signal building_constructed(building: BuildingInstance)
signal building_upgraded(building: BuildingInstance)
signal building_demolished(building: BuildingInstance)
signal building_production(building: BuildingInstance, produced: Dictionary)

func _init() -> void:
	if ref == null:
		ref = self
		name = "BuildingSystem"
	else:
		queue_free()

func _ready() -> void:
	if TickManager.ref:
		TickManager.ref.tick.connect(_on_tick)
	
	add_to_group("save_load_systems")

func construct_building(building_type: String, slot_id: String, position: Vector2 = Vector2.ZERO) -> BuildingInstance:
	var template = DataBuilding.get_building_data(building_type)
	if template.is_empty():
		push_error("Building type not found: " + building_type)
		return null
	
	var cost = template.construction_cost
	if not ResourceManager.ref.consume_resources(cost):
		print("Cannot afford building: " + building_type)
		return null
	
	var building = BuildingInstance.new(building_type, slot_id)
	building.position = position
	
	if Game.ref and Game.ref.data.progression:
		Game.ref.data.progression.buildings.append(building)
	
	building_constructed.emit(building)
	
	print("Building constructed: %s at %s" % [building_type, slot_id])
	return building

func demolish_building(instance_id: String) -> bool:
	var building = get_building_by_id(instance_id)
	if not building:
		return false
	
	building.demolish()
	
	if Game.ref and Game.ref.data.progression:
		Game.ref.data.progression.buildings.erase(building)
	
	building_demolished.emit(building)
	
	print("Building demolished: " + instance_id)
	return true

func upgrade_building(instance_id: String) -> bool:
	var building = get_building_by_id(instance_id)
	if not building:
		return false
	
	if building.upgrade():
		building_upgraded.emit(building)
		print("Building upgraded: %s to level %d" % [instance_id, building.current_level])
		return true
	
	return false

func set_building_workers(instance_id: String, worker_count: int) -> bool:
	var building = get_building_by_id(instance_id)
	if not building:
		return false
	
	return building.set_workers(worker_count)

func get_building_by_id(instance_id: String) -> BuildingInstance:
	if not Game.ref or not Game.ref.data.progression:
		return null
	
	for building in Game.ref.data.progression.buildings:
		if building.instance_id == instance_id:
			return building
	
	return null

func get_buildings_at_slot(slot_id: String) -> Array[BuildingInstance]:
	var result : Array[BuildingInstance] = []
	
	if not Game.ref or not Game.ref.data.progression:
		return result
	
	for building in Game.ref.data.progression.buildings:
		if building.slot_id == slot_id:
			result.append(building)
	
	return result

func _on_tick() -> void:
	if not Game.ref or not Game.ref.data.progression:
		return
	
	for building in Game.ref.data.progression.buildings:
		if building.is_active and building.assigned_workers > 0:
			if building.process_production():
				var production = building.get_current_production()
				if not production.is_empty():
					building_production.emit(building, production)

func save_state() -> Dictionary:
	return {}

func load_state(data: Dictionary) -> void:
	if not Game.ref or not Game.ref.data.progression:
		return
	
	for building in Game.ref.data.progression.buildings:
		_recreate_building_visual(building)

func _recreate_building_visual(building: BuildingInstance) -> void:
	building_constructed.emit(building)
