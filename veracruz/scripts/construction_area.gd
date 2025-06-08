class_name ConstructionArea
extends Area2D

enum TYPE {
	NORMAL, 
	WALL, 
	WAREHOUSE
}

@export_enum("NORMAL", "WALL", "WAREHOUSE")
var area_type : int
@export var center_position : Vector2 = Vector2.ZERO
@export var is_occupied : bool = false

func _ready() -> void:
	add_to_group("construction_areas")
	
