class_name DataProgression
extends Resource

## Estado temporal (se mueve a TickManager pero lo guardamos aquí para saves)
@export var total_ticks : int = 0
@export var current_month : int = 1  # 1-12
@export var current_year : int = 1519

## Estadísticas de recursos
@export var total_resources_produced : Dictionary = {}
@export var total_resources_consumed : Dictionary = {}

## Estado de edificios (para save/load)
@export var buildings_data : Array = []  # Array[BuildingData] cuando lo creemos
@export var extractors_data : Array = []  # Array[ExtractorData] cuando lo creemos

## Workers asignados
@export var assigned_workers : Dictionary = {}  # building_id -> workers
