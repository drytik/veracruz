class_name ResourceManager
extends Node

static var ref : ResourceManager

signal resource_changed(resource_name: String, new_amount: int, old_amount: int)
signal resource_limit_reached(resource_name: String)

func _init() -> void:
	if ref == null:
		ref = self
	else:
		queue_free()

func _ready() -> void:
	pass

func add_resource(resource_name: String, amount: int) -> bool:
	if amount == 0:
		return true
	
	var current = Game.ref.data.resources.get(resource_name)
	if current == null:
		push_error("Resource not found: " + resource_name)
		return false
	
	var old_amount = current
	
	var limit = Game.ref.data.warehouse_limits.get(resource_name, 9999)
	var new_amount = current + amount
	
	if new_amount < 0:
		return false
	
	if new_amount > limit:
		new_amount = limit
		emit_signal("resource_limit_reached", resource_name)
	
	Game.ref.data.resources.set(resource_name, new_amount)
	
	if amount > 0:
		_track_produced(resource_name, amount)
	else:
		_track_consumed(resource_name, abs(amount))
	
	emit_signal("resource_changed", resource_name, new_amount, old_amount)
	return true

func consume_resource(resource_name: String, amount: int) -> bool:
	var current = get_resource(resource_name)
	if current >= amount:
		return add_resource(resource_name, -amount)
	return false

func has_resources(requirements: Dictionary) -> bool:
	for resource in requirements:
		if get_resource(resource) < requirements[resource]:
			return false
	return true

func consume_resources(requirements: Dictionary) -> bool:
	if not has_resources(requirements):
		return false
	
	for resource in requirements:
		consume_resource(resource, requirements[resource])
	
	return true

func get_resource(resource_name: String) -> int:
	var value = Game.ref.data.resources.get(resource_name)
	if value == null:
		return 0
	return value

func get_resource_limit(resource_name: String) -> int:
	return Game.ref.data.warehouse_limits.get(resource_name, 9999)

func _track_produced(resource_name: String, amount: int) -> void:
	if not Game.ref.data.progression.total_resources_produced.has(resource_name):
		Game.ref.data.progression.total_resources_produced[resource_name] = 0
	Game.ref.data.progression.total_resources_produced[resource_name] += amount

func _track_consumed(resource_name: String, amount: int) -> void:
	if not Game.ref.data.progression.total_resources_consumed.has(resource_name):
		Game.ref.data.progression.total_resources_consumed[resource_name] = 0
	Game.ref.data.progression.total_resources_consumed[resource_name] += amount
