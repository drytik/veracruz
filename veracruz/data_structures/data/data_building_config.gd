class_name DataBuildingConfig
extends Resource

@export var name : String = "Building"
@export var description : String = ""
@export var allowed_area_types : Array[int] = []  # Tipos de área donde puede construirse

@export_group("Workers")
@export var workers_required : Array[int] = [2, 3, 4, 5]  # Por nivel

@export_group("Production")
@export var input_resources : Dictionary = {}  # {"wood": 24} consumo anual
@export var output_resources : Dictionary = {}  # {"planks": 12} producción anual
@export var production_cycle : int = 3  # Meses entre producciones (3 = trimestral)

@export_group("Construction")
@export var construction_cost : Dictionary = {"wood": 50, "stone": 20}
@export var construction_time : int = 1  # Meses para construir

@export_group("Upgrade Costs")
@export var upgrade_costs : Array[Dictionary] = [
	{"wood": 100, "stone": 50, "tools": 10},
	{"wood": 200, "stone": 100, "tools": 20},
	{"wood": 400, "stone": 200, "tools": 40}
]

@export_group("Visuals")
@export var texture_paths : Array[String] = []
@export var placeholder_color : Color = Color(0.3, 0.3, 0.5, 0.8)
