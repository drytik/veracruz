extends CanvasLayer

@onready var construction_menu = $VBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer
@onready var port_button = $VBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building0/VBoxContainer/Port

signal building_selected

var buildings : Dictionary = {
	"Port": {"name": "Port"}
	}

func _ready() -> void:
	port_button.connect("pressed", _on_building_selected.bind("Port"))
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		pass

func _on_building_selected(building_key : String) -> void:
	var building_data = buildings.get(building_key, null)
	if building_data:
		print("Building selected: " + building_data["name"])
	emit_signal("building_selected")
	
