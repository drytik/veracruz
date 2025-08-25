class_name WorldUIManager
extends CanvasLayer

@onready var world_scene: Node2D = $".."

func _ready() -> void:
	# Configurar la capa para que esté visible
	layer = 1
	
	# Conectar con todas las zonas de extractores
	_connect_extractor_zones()
	
	# TEMPORAL: Crear una zona de prueba programáticamente (diferido)
	call_deferred("_create_test_zone")
	
	print("WorldUIManager ready")

func _create_test_zone() -> void:
	# FUNCIÓN TEMPORAL DE PRUEBA - Comentar cuando no sea necesaria
	return  # Desactivada
	
	# Crear zona de prueba en una posición visible
	var test_area = Area2D.new()
	test_area.position = Vector2(400, 300)  # Posición en pantalla
	test_area.input_pickable = true
	
	# Añadir collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 100)
	collision.shape = shape
	test_area.add_child(collision)
	
	# Añadir visual para ver dónde está
	var visual = ColorRect.new()
	visual.size = Vector2(100, 100)
	visual.position = Vector2(-50, -50)  # Centrar
	visual.color = Color(1, 0, 0, 0.3)  # Rojo semi-transparente
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ignorar mouse para no bloquear el Area2D
	test_area.add_child(visual)
	
	# Añadir el script y configurar
	test_area.set_script(load("res://scripts/construction_area.gd"))
	test_area.is_extractor_zone = true
	test_area.extractor_type = "lumbermill"
	
	# Añadir a la escena usando call_deferred para evitar problemas
	world_scene.call_deferred("add_child", test_area)

func _connect_extractor_zones() -> void:
	# Esperar un frame para asegurar que todo está cargado
	await get_tree().process_frame
	
	var zones = get_tree().get_nodes_in_group("extractor_zones")
	print("Found %d extractor zones" % zones.size())
	
	for zone in zones:
		if zone is ConstructionArea:
			# Ya no necesitamos conectar nada, el área maneja su propio click
			print("Zone registered: %s" % zone.zone_id)

func _input(event: InputEvent) -> void:
	# Cerrar popups con ESC
	if event.is_action_pressed("ui_cancel"):
		if PopupManager.ref and PopupManager.ref.current_popup:
			PopupManager.ref.close_current_popup()
