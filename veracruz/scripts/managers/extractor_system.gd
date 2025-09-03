class_name ExtractorSystem
extends Node

static var ref : ExtractorSystem

signal extractor_constructed(extractor: ExtractorInstance)
signal extractor_upgraded(extractor: ExtractorInstance)
signal extractor_demolished(extractor: ExtractorInstance)
signal extractor_production(extractor: ExtractorInstance, resource: String, amount: int)

const ZONE_CONQUEST_COST = {"piece_of_8": 500}

func _init() -> void:
	if ref == null:
		ref = self
		name = "ExtractorSystem"
	else:
		queue_free()

func _ready() -> void:
	if TickManager.ref:
		TickManager.ref.tick.connect(_on_tick)
	
	add_to_group("save_load_systems")

func can_construct_extractor(category: String, resource: String) -> bool:
	if not is_resource_unlocked(category, resource):
		return false
	
	var template = DataExtractor.get_extractor_data(category)
	if template.is_empty():
		return false
	
	var cost = template.construction_cost
	return ResourceManager.ref.has_resources(cost)

func construct_extractor(category: String, resource: String, zone_id: String, position: Vector2 = Vector2.ZERO) -> ExtractorInstance:
	if not can_construct_extractor(category, resource):
		return null
	
	var template = DataExtractor.get_extractor_data(category)
	var cost = template.construction_cost
	
	if not ResourceManager.ref.consume_resources(cost):
		print("Cannot afford extractor")
		return null
	
	var extractor = ExtractorInstance.new(category, resource, zone_id)
	extractor.position = position
	
	if Game.ref and Game.ref.data.progression:
		Game.ref.data.progression.extractors.append(extractor)
	
	extractor_constructed.emit(extractor)
	
	print("Extractor constructed: %s (%s) at zone %s" % [category, resource, zone_id])
	return extractor

func demolish_extractor(instance_id: String) -> bool:
	var extractor = get_extractor_by_id(instance_id)
	if not extractor:
		return false
	
	extractor.demolish()
	
	if Game.ref and Game.ref.data.progression:
		Game.ref.data.progression.extractors.erase(extractor)
	
	extractor_demolished.emit(extractor)
	
	print("Extractor demolished: " + instance_id)
	return true

func upgrade_extractor(instance_id: String) -> bool:
	var extractor = get_extractor_by_id(instance_id)
	if not extractor:
		return false
	
	if extractor.upgrade():
		extractor_upgraded.emit(extractor)
		print("Extractor upgraded: %s to level %d" % [instance_id, extractor.current_level])
		return true
	
	return false

func set_extractor_workers(instance_id: String, worker_count: int) -> bool:
	var extractor = get_extractor_by_id(instance_id)
	if not extractor:
		return false
	
	return extractor.set_workers(worker_count)

func get_extractor_by_id(instance_id: String) -> ExtractorInstance:
	if not Game.ref or not Game.ref.data.progression:
		return null
	
	for extractor in Game.ref.data.progression.extractors:
		if extractor.instance_id == instance_id:
			return extractor
	
	return null

func get_extractor_at_zone(zone_id: String) -> ExtractorInstance:
	if not Game.ref or not Game.ref.data.progression:
		return null
	
	for extractor in Game.ref.data.progression.extractors:
		if extractor.zone_id == zone_id:
			return extractor
	
	return null

func is_zone_unlocked(zone_id: String) -> bool:
	if not Game.ref or not Game.ref.data.progression:
		return false
	
	return zone_id in Game.ref.data.progression.unlocked_zones

func unlock_zone(zone_id: String) -> bool:
	if is_zone_unlocked(zone_id):
		return true
	
	if not ResourceManager.ref.consume_resources(ZONE_CONQUEST_COST):
		print("Cannot afford zone conquest")
		return false
	
	if Game.ref and Game.ref.data.progression:
		Game.ref.data.progression.unlocked_zones.append(zone_id)
	
	print("Zone unlocked: " + zone_id)
	return true

func is_resource_unlocked(category: String, resource: String) -> bool:
	if not Game.ref or not Game.ref.data.progression:
		return false
	
	return DataExtractor.is_resource_unlocked(category, resource, Game.ref.data.progression.unlocked_resources)

func get_available_resources(category: String) -> Array:
	if not Game.ref or not Game.ref.data.progression:
		return []
	
	return DataExtractor.get_available_resources_for_zone(category, Game.ref.data.progression.unlocked_resources)

func unlock_resource(category: String, resource: String) -> bool:
	if is_resource_unlocked(category, resource):
		return true
	
	if Game.ref and Game.ref.data.progression:
		if category not in Game.ref.data.progression.unlocked_resources:
			Game.ref.data.progression.unlocked_resources[category] = []
		
		Game.ref.data.progression.unlocked_resources[category].append(resource)
	
	print("Resource unlocked: %s for %s" % [resource, category])
	return true

func _on_tick() -> void:
	if not Game.ref or not Game.ref.data.progression:
		return
	
	for extractor in Game.ref.data.progression.extractors:
		if extractor.is_active and extractor.assigned_workers > 0:
			if extractor.process_production():
				var production = extractor.get_current_production()
				if production > 0:
					extractor_production.emit(extractor, extractor.selected_resource, production)

func save_state() -> Dictionary:
	return {}

func load_state(data: Dictionary) -> void:
	if not Game.ref or not Game.ref.data.progression:
		return
	
	for extractor in Game.ref.data.progression.extractors:
		_recreate_extractor_visual(extractor)

func _recreate_extractor_visual(extractor: ExtractorInstance) -> void:
	extractor_constructed.emit(extractor)
