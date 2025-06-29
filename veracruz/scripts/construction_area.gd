class_name ConstructionArea
extends Area2D

enum TYPE {
	x2x1, 
	WALL, 
	WAREHOUSE
}

@export_enum("x2x1", "WALL", "WAREHOUSE")
var area_type : int
@export var center_position : Vector2 = Vector2.ZERO
@export var is_occupied : bool = false

var highlight_shape: ColorRect

func _ready() -> void:
	add_to_group("construction_areas")
	_create_highlight()
	
func _create_highlight() -> void: 
	highlight_shape = ColorRect.new()
	highlight_shape.color = Color(1.0, 1.0, 1.0, 0.3)
	highlight_shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight_shape.visible = false 
	
	add_child(highlight_shape)
	_adjust_highlight_size()
	
func _adjust_highlight_size() -> void: 
	var collision_shape: CollisionShape2D = get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape: 
		var shape = collision_shape.shape
		var shape_size: Vector2
		
		if shape is RectangleShape2D:
			var base_size = shape.size
			var final_size = Vector2(
				abs(base_size.x * collision_shape.scale.x),
				abs(base_size.y * collision_shape.scale.y)
			) 


			var shape_pos = collision_shape.position
		
			highlight_shape.size = final_size
			highlight_shape.position = shape_pos - (final_size / 2)
			highlight_shape.rotation = collision_shape.rotation
		
			print("Área: ", name)
			#print("Size final: ", final_size)
			print("Position: ", highlight_shape.position)
		
	else: 
		highlight_shape.size = Vector2(100, 100)
		highlight_shape.position = collision_shape.position - Vector2(50, 50)
		
func show_highlight() -> void: 
	if not is_occupied: 
		highlight_shape.visible = true
		
func hide_highlight() -> void: 
	highlight_shape.visible = false
	
