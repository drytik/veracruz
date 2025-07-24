class_name ConstructionArea
extends Area2D

enum TYPE {
	x2x1, 
	x2x2,
	x3x2, 
	WALL, 
	WORKSHOP,
	PORT
}

@export_enum("x2x1", "x2x2", "x3x2", "WALL", "WORKSHOP", "PORT")
var area_type : int
@export var center_position : Vector2 = Vector2.ZERO
@export var is_occupied : bool = false

var highlight_shape: Node2D

func _ready() -> void:
	add_to_group("construction_areas")
	_create_highlight()
	
	
func _create_highlight() -> void: 
	# Duplicar el CollisionShape2D existente
	var collision_shape = get_node("CollisionShape2D")
	if collision_shape:
		highlight_shape = collision_shape.duplicate()
		
		# Convertir a visual con Polygon2D
		var polygon = Polygon2D.new()
		polygon.color = Color(1.0, 1.0, 1.0, 0.3)
		# Si es RectangleShape2D, crear el polígono
		if collision_shape.shape is RectangleShape2D:
			var size = collision_shape.shape.size
			var points = PackedVector2Array([
				Vector2(-size.x/2, -size.y/2),
				Vector2(size.x/2, -size.y/2), 
				Vector2(size.x/2, size.y/2),
				Vector2(-size.x/2, size.y/2)
			])
			polygon.polygon = points
			polygon.z_index = 1
		
		# Limpiar el highlight duplicado y añadir el polígono
		for child in highlight_shape.get_children():
			child.queue_free()
		
		highlight_shape.add_child(polygon)
		highlight_shape.visible = false
		highlight_shape.z_index = 1
		add_child(highlight_shape)
		
func show_highlight() -> void: 
	if not is_occupied: 
		highlight_shape.visible = true
		
func hide_highlight() -> void: 
	highlight_shape.visible = false
	
