class_name WorldUIManager
extends CanvasLayer

@onready var world_scene: Node2D = $".."

func _ready() -> void:
	# Configurar la capa para que esté visible
	layer = 1
	
	# Conectar con todas las zonas de extractores
	_connect_extractor_zones()
	
	# TEMPORAL: Crear una zona de prueba programáticamente (diferido)
	# call_deferred("_create_test_zone")  # Desactivado por defecto
	
	print("WorldUIManager ready")

func _create_test_zone() -> void:
	# FUNCIÓN TEMPORAL DE PRUEBA - Comentar cuando no sea necesaria
	return  # Desactivada
	
	# Crear zona de prueba en una posición visible
	var test_area = WorldExtractorZone.new()
	test_area.position = Vector2(400, 300)  # Posición en pantalla
	test_area.zone_category = "lumbermill"
	test_area.zone_name = "Zona de Prueba"
	test_area.is_initial_zone = true
	
	# Añadir a la escena
	world_scene.call_deferred("add_child", test_area)
	
	print("Test zone created")

func _connect_extractor_zones() -> void:
	# Esperar un frame para asegurar que todo está cargado
	await get_tree().process_frame
	
	var zones = get_tree().get_nodes_in_group("world_extractor_zones")
	print("Found %d extractor zones" % zones.size())
	
	for zone in zones:
		if zone is WorldExtractorZone:  # CAMBIADO: WorldExtractorZone en lugar de ConstructionArea
			print("Zone registered: %s" % zone.zone_id)

func _input(event: InputEvent) -> void:
	# Cerrar popups con ESC
	if event.is_action_pressed("ui_cancel"):
		if PopupManager.ref and PopupManager.ref.current_popup:
			PopupManager.ref.close_current_popup()

func refresh_from_save() -> void:
	# Función llamada cuando se carga un save
	print("WorldUIManager: Refreshing from save")
	
	# Reconectar zonas si es necesario
	_connect_extractor_zones()
	
	# Actualizar visuales de todas las zonas
	var zones = get_tree().get_nodes_in_group("world_extractor_zones")
	for zone in zones:
		if zone is WorldExtractorZone:
			# Forzar actualización del estado visual
			if zone.has_method("_initialize_zone_state"):
				zone._initialize_zone_state()
