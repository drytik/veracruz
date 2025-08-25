class_name Data
extends Resource

@export var resources : DataResources = DataResources.new()
@export var progression : DataProgression = DataProgression.new()
@export var settings : DataSettings = DataSettings.new()

## Límites del warehouse por nivel
@export var warehouse_limits : Dictionary = {
	"wood": 100, 
	"planks": 100, 
	"stone": 100, 
	"clay": 100,
	"iron": 50, 
	"tools": 20, 
	"fruits": 100, 
	"corn": 100,
	"flour": 100, 
	"cotton": 100, 
	"cloth": 50,
	"silver": 50,
	"gold": 30,
	"gold_bars": 30,
	"piece_of_8": 500,
	"dyes": 50,
	"cocoa": 50,
	"agave": 50,
	"beverages": 50,
	# Foráneos
	"livestock": 20,
	"weapons": 30,
	"glass": 30,
	"books": 20,
	"pottery": 50
}
