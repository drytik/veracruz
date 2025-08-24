class_name TickManager
extends Node

signal tick
signal month_passed
signal year_passed

static var ref : TickManager

var tick_timer : float = 0.0
var tick_rate : float = 0.25  # 0.25 segundos = 1 tick (4 ticks = 1 mes para testing)
var ticks_per_month : int = 4  # Configurable para testing
var current_tick_in_month : int = 0

# Variables de tiempo del juego
var current_month : int = 1  # 1-12
var current_year : int = 1519
var total_ticks : int = 0

# Control de velocidad
enum GameSpeed { PAUSED = 0, NORMAL = 1, FAST = 2, VERY_FAST = 3 }
var game_speed : GameSpeed = GameSpeed.NORMAL

func _init() -> void:
	if ref == null:
		ref = self
	else:
		queue_free()

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if game_speed == GameSpeed.PAUSED:
		return
	
	tick_timer += delta * float(game_speed)
	
	if tick_timer >= tick_rate:
		tick_timer -= tick_rate
		_execute_tick()

func _execute_tick() -> void:
	total_ticks += 1
	current_tick_in_month += 1
	
	emit_signal("tick")
	
	# Verificar si pasó un mes
	if current_tick_in_month >= ticks_per_month:
		current_tick_in_month = 0
		current_month += 1
		
		# Verificar fin de año
		if current_month > 12:
			current_month = 1
			current_year += 1
			emit_signal("year_passed")
		
		emit_signal("month_passed")
		
	# Llamar a todos los que necesiten actualización por tick
	get_tree().call_group("tick_receivers", "on_tick")

func set_game_speed(speed: GameSpeed) -> void:
	game_speed = speed

func get_month_name() -> String:
	var months = ["January", "February", "March", "April", "May", "June",
				  "July", "August", "September", "October", "November", "December"]
	return months[current_month - 1]

func get_date_string() -> String:
	return "%s, %d" % [get_month_name(), current_year]
