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

func assign_workers(building_id: String, amount: int) -> bool:
	# Validar que el juego y los datos existen
	if not Game.ref or not Game.ref.data:
		push_error("Game not initialized when assigning workers")
		return false
	
	if not Game.ref.data.resources:
		push_error("Game resources not initialized")
		return false
		
	# Validar que idle_workers existe y es válido
	if not "idle_workers" in Game.ref.data.resources:
		push_error("idle_workers not found in resources")
		return false
	
	# Validar que progression existe
	if not Game.ref.data.progression:
		push_error("Game progression not initialized")
		return false
	
	var current_assigned = get_assigned_workers(building_id)
	var difference = amount - current_assigned
	
	var idle = Game.ref.data.resources.idle_workers
	
	# Validar que hay suficientes workers disponibles
	if difference > 0:
		if idle < 0:
			push_warning("Idle workers is negative: %d" % idle)
			Game.ref.data.resources.idle_workers = 0
			idle = 0
			
		if difference > idle:
			emit_signal("not_enough_workers", difference, idle)
			return false
	
	# Actualizar idle workers
	Game.ref.data.resources.idle_workers = max(0, idle - difference)
	
	# Actualizar asignación
	if amount == 0:
		if Game.ref.data.progression.assigned_workers.has(building_id):
			Game.ref.data.progression.assigned_workers.erase(building_id)
	else:
		Game.ref.data.progression.assigned_workers[building_id] = amount
	
	emit_signal("workers_assigned", building_id, amount)
	emit_signal("workers_updated")
	return true

func free_workers(building_id: String) -> void:
	var current = get_assigned_workers(building_id)
	if current > 0:
		assign_workers(building_id, 0)

func get_assigned_workers(building_id: String) -> int:
	if not Game.ref or not Game.ref.data or not Game.ref.data.progression:
		return 0
		
	return Game.ref.data.progression.assigned_workers.get(building_id, 0)

func get_total_assigned_workers() -> int:
	if not Game.ref or not Game.ref.data or not Game.ref.data.progression:
		return 0
		
	var total = 0
	for building_id in Game.ref.data.progression.assigned_workers:
		total += Game.ref.data.progression.assigned_workers[building_id]
	return total

func update_idle_workers() -> void:
	if not Game.ref or not Game.ref.data or not Game.ref.data.resources:
		push_error("Cannot update idle workers - Game not initialized")
		return
		
	var total_assigned = get_total_assigned_workers()
	var population = Game.ref.data.resources.get("population")
	
	# Asegurar que idle_workers nunca sea negativo
	Game.ref.data.resources.idle_workers = max(0, population - total_assigned)
	emit_signal("workers_updated")

func validate_all_assignments() -> void:
	# Función helper para validar todas las asignaciones después de cargar
	if not Game.ref or not Game.ref.data or not Game.ref.data.progression:
		return
		
	var to_remove = []
	var total = 0
	
	for building_id in Game.ref.data.progression.assigned_workers:
		var assigned = Game.ref.data.progression.assigned_workers[building_id]
		
		# Validar que la asignación es positiva
		if assigned <= 0:
			to_remove.append(building_id)
		else:
			total += assigned
	
	# Limpiar asignaciones inválidas
	for building_id in to_remove:
		Game.ref.data.progression.assigned_workers.erase(building_id)
	
	# Actualizar idle workers
	update_idle_workers()
