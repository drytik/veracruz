class_name DataProgression
extends Resource

## Estado temporal (se mueve a TickManager pero lo guardamos aquí para saves)
@export var total_ticks : int = 0
@export var current_month : int = 1  # 1-12
@export var current_year : int = 1519

## Estadísticas de recursos
@export var total_resources_produced : Dictionary = {}
@export var total_resources_consumed : Dictionary = {}

## Estado de edificios y extractores (para save/load)
@export var buildings : Array[BuildingInstance] = []
@export var extractors : Array[ExtractorInstance] = []

## Zonas y recursos desbloqueados
@export var unlocked_zones : Array[String] = []  # IDs de zonas conquistadas
@export var unlocked_resources : Dictionary = {
	"quarry": ["clay"],       # Clay desbloqueado por defecto
	"plantation": ["fruits"]  # Fruits desbloqueado por defecto
}

## Workers asignados (redundante con instances pero útil para búsqueda rápida)
@export var assigned_workers : Dictionary = {}  # instance_id -> workers
