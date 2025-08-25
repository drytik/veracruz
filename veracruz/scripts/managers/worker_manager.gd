class_name WorkerManager
extends Node

static var ref : WorkerManager

signal workers_updated
signal workers_assigned(building_id: String, amount: int)
signal not_enough_workers(required: int, available: int)

func _init() -> void:
	if ref == null:
		ref = self
	else:
		queue_free()

func _ready() -> void:
	pass

## Asignar workers a un edificio
func assign_workers(building_id: String, amount: int) -> bool:
	var current_assigned = get_assigned_workers(building_id)
	var difference = amount - current_assigned
	
	# Si necesitamos más workers
	if difference > 0:
		if difference > Game.ref.data.resources.idle_workers:
			emit_signal("not_enough_workers", difference, Game.ref.data.resources.idle_workers)
			return false
	
	# Actualizar idle_workers
	Game.ref.data.resources.idle_workers -= difference
	
	# Actualizar asignación
	if amount == 0:
		Game.ref.data.progression.assigned_workers.erase(building_id)
	else:
		Game.ref.data.progression.assigned_workers[building_id] = amount
	
	emit_signal("workers_assigned", building_id, amount)
	emit_signal("workers_updated")
	return true

## Liberar todos los workers de un edificio
func free_workers(building_id: String) -> void:
	var current = get_assigned_workers(building_id)
	if current > 0:
		assign_workers(building_id, 0)

## Obtener workers asignados a un edificio
func get_assigned_workers(building_id: String) -> int:
	return Game.ref.data.progression.assigned_workers.get(building_id, 0)

## Obtener total de workers asignados
func get_total_assigned_workers() -> int:
	var total = 0
	for building_id in Game.ref.data.progression.assigned_workers:
		total += Game.ref.data.progression.assigned_workers[building_id]
	return total

## Actualizar workers idle cuando cambia la población
func update_idle_workers() -> void:
	var total_assigned = get_total_assigned_workers()
	Game.ref.data.resources.idle_workers = Game.ref.data.resources.population - total_assigned
	emit_signal("workers_updated")
