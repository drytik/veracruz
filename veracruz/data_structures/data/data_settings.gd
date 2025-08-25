class_name DataSettings
extends Resource

enum GameSpeed { PAUSED = 0, NORMAL = 1, FAST = 2, VERY_FAST = 3 }

@export var game_speed : GameSpeed = GameSpeed.NORMAL
@export var auto_save_enabled : bool = true
@export var master_volume : float = 1.0
@export var sfx_volume : float = 1.0
@export var music_volume : float = 1.0
