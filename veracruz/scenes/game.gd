class_name Game
extends Node

## Singleton ref

static var ref : Game 

func _init() -> void:
	if ref == null: 
		ref == self
	else: 
		queue_free()

## Data constructor

var data : Data = Data.new()
