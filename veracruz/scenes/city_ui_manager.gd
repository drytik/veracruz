extends CanvasLayer

@onready var construction_menu = $VBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer
@onready var port_button = $VBoxContainer/PanelContainer/HBoxContainer2/HBoxContainer/Building0/VBoxContainer/Port

signal building_selected

func _ready() -> void:
	port_button.connect("pressed", _on_building_selected)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		pass

func _on_building_selected(): 
	print("Building selected")
	emit_signal("building_selected")
