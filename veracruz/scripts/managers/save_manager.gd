class_name SaveManager
extends Node

static var ref : SaveManager

const SAVE_PATH = "user://savegame.tres"
const SETTINGS_PATH = "user://settings.tres"
const BACKUP_PATH = "user://savegame_backup.tres"
const CURRENT_SAVE_VERSION = 1

signal game_saved
signal game_loaded
signal save_failed(reason: String)
signal load_failed(reason: String)

func _init() -> void:
	if ref == null:
		ref = self
		name = "SaveManager"
	else:
		queue_free()

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = 60.0
	timer.timeout.connect(_auto_save)
	timer.autostart = true
	add_child(timer)

func save_game(path: String = SAVE_PATH) -> bool:
	if not Game.ref or not Game.ref.data:
		save_failed.emit("No game data to save")
		return false
	
	# Añadir versión al save
	Game.ref.data.set_meta("save_version", CURRENT_SAVE_VERSION)
	Game.ref.data.set_meta("save_date", Time.get_unix_time_from_system())
	
	# Actualizar estado del tiempo
	if TickManager.ref:
		Game.ref.data.progression.total_ticks = TickManager.ref.total_ticks
		Game.ref.data.progression.current_month = TickManager.ref.current_month
		Game.ref.data.progression.current_year = TickManager.ref.current_year
	
	# Crear backup si existe save anterior
	if path == SAVE_PATH and FileAccess.file_exists(SAVE_PATH):
		_create_backup()
	
	# Guardar el archivo
	var result = ResourceSaver.save(Game.ref.data, path)
	
	if result == OK:
		game_saved.emit()
		print("Game saved successfully to: %s (version %d)" % [path, CURRENT_SAVE_VERSION])
		return true
	else:
		save_failed.emit("Failed to write save file: error code %d" % result)
		print("Save failed with error: " + str(result))
		return false

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		load_failed.emit("Save file not found")
		return false
	
	# Cargar los datos
	var loaded_data = load(path)
	
	if not loaded_data:
		load_failed.emit("Failed to load save file")
		return false
		
	if not loaded_data is Data:
		load_failed.emit("Invalid save file format")
		return false
	
	# Verificar versión y migrar si es necesario
	var save_version = loaded_data.get_meta("save_version", 0)
	if save_version != CURRENT_SAVE_VERSION:
		print("Migrating save from version %d to %d" % [save_version, CURRENT_SAVE_VERSION])
		if not _migrate_save_data(loaded_data, save_version):
			load_failed.emit("Failed to migrate save data")
			return false
	
	if not Game.ref:
		load_failed.emit("Game not initialized")
		return false
	
	# Reemplazar datos
	Game.ref.data = loaded_data
	
	# Restaurar estado del tiempo
	if TickManager.ref and Game.ref.data.progression:
		TickManager.ref.total_ticks = Game.ref.data.progression.total_ticks
		TickManager.ref.current_month = Game.ref.data.progression.current_month
		TickManager.ref.current_year = Game.ref.data.progression.current_year
	
	# Validar workers después de cargar
	if WorkerManager.ref:
		WorkerManager.ref.validate_all_assignments()
	
	# Recrear estado del juego
	_recreate_game_state()
	
	game_loaded.emit()
	
	var save_date = loaded_data.get_meta("save_date", 0)
	if save_date > 0:
		var time_dict = Time.get_datetime_dict_from_unix_time(int(save_date))
		print("Game loaded successfully from: %s (saved on %02d/%02d/%04d)" % [
			path, 
			time_dict.day, 
			time_dict.month, 
			time_dict.year
		])
	else:
		print("Game loaded successfully from: " + path)
	
	return true

func _migrate_save_data(data: Data, from_version: int) -> bool:
	# Migrar datos según la versión
	match from_version:
		0:
			# Save sin versión (primera versión)
			print("Migrating from unversioned save")
			
			# Asegurar que progression existe
			if not data.progression:
				data.progression = DataProgression.new()
			
			# Añadir campos nuevos si faltan
			if not data.progression.has("unlocked_resources"):
				data.progression.unlocked_resources = {
					"quarry": ["clay"],
					"plantation": ["fruits"]
				}
			
			# Asegurar que los arrays están inicializados
			if not data.progression.has("buildings"):
				data.progression.buildings = []
			
			if not data.progression.has("extractors"):
				data.progression.extractors = []
				
			if not data.progression.has("unlocked_zones"):
				data.progression.unlocked_zones = []
			
			# Migración exitosa
			return true
		_:
			push_warning("Unknown save version: " + str(from_version))
			# Intentar cargar de todos modos
			return true
	
	return false

func has_save_file(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

func delete_save(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	
	var dir = DirAccess.open("user://")
	if dir:
		var result = dir.remove(path)
		return result == OK
	
	return false

func get_save_info(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"exists": true, "error": "Cannot read file"}
	
	var modified_time = file.get_modified_time(path)
	file.close()
	
	# Cargar temporalmente para obtener info
	var temp_data = load(path)
	if temp_data and temp_data is Data:
		var info = {
			"exists": true,
			"modified_time": modified_time,
			"version": temp_data.get_meta("save_version", 0),
			"save_date": temp_data.get_meta("save_date", 0)
		}
		
		if temp_data.progression:
			info["year"] = temp_data.progression.current_year
			info["month"] = temp_data.progression.current_month
			info["total_ticks"] = temp_data.progression.total_ticks
			info["buildings_count"] = temp_data.progression.buildings.size()
			info["extractors_count"] = temp_data.progression.extractors.size()
		
		return info
	
	return {"exists": true, "modified_time": modified_time, "error": "Invalid save format"}

func _create_backup() -> void:
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("savegame.tres"):
		var result = dir.copy("savegame.tres", "savegame_backup.tres")
		if result == OK:
			print("Backup created successfully")
		else:
			push_warning("Failed to create backup: error " + str(result))

func _auto_save() -> void:
	if Game.ref and Game.ref.data and Game.ref.data.settings:
		if Game.ref.data.settings.auto_save_enabled:
			save_game()

func _recreate_game_state() -> void:
	# Notificar a los sistemas para recrear visuales
	if BuildingSystem.ref:
		BuildingSystem.ref.load_state({})
	
	if ExtractorSystem.ref:
		ExtractorSystem.ref.load_state({})
	
	# Notificar a todos los UI managers
	get_tree().call_group("ui_managers", "refresh_from_save")

func save_settings() -> bool:
	if not Game.ref or not Game.ref.data or not Game.ref.data.settings:
		push_error("Cannot save settings - no settings data")
		return false
	
	var result = ResourceSaver.save(Game.ref.data.settings, SETTINGS_PATH)
	
	if result == OK:
		print("Settings saved successfully")
		return true
	else:
		push_error("Failed to save settings: error " + str(result))
		return false

func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("No settings file found, using defaults")
		return false
	
	var loaded_settings = load(SETTINGS_PATH)
	
	if not loaded_settings:
		push_error("Failed to load settings file")
		return false
	
	if loaded_settings and loaded_settings is DataSettings:
		if Game.ref and Game.ref.data:
			Game.ref.data.settings = loaded_settings
			print("Settings loaded successfully")
			return true
		else:
			push_error("Cannot apply settings - Game not initialized")
			return false
	
	push_error("Invalid settings file format")
	return false

func create_new_game() -> void:
	# Función helper para crear una nueva partida
	if not Game.ref:
		push_error("Cannot create new game - Game not initialized")
		return
	
	# Crear nuevos datos limpios
	Game.ref.data = Data.new()
	
	# Asegurar que progression está inicializado
	if not Game.ref.data.progression:
		Game.ref.data.progression = DataProgression.new()
	
	# Resetear tiempo
	if TickManager.ref:
		TickManager.ref.total_ticks = 0
		TickManager.ref.current_month = 1
		TickManager.ref.current_year = 1519
	
	# Notificar a todos los sistemas
	_recreate_game_state()
	
	print("New game created")

func quick_save() -> bool:
	# Guardado rápido con feedback
	print("Quick saving...")
	return save_game()

func quick_load() -> bool:
	# Carga rápida con verificación
	if has_save_file():
		print("Quick loading...")
		return load_game()
	else:
		push_warning("No save file found for quick load")
		return false

func export_save(export_path: String) -> bool:
	# Exportar save a una ubicación específica (para compartir)
	if not has_save_file():
		push_error("No save file to export")
		return false
	
	var dir = DirAccess.open("user://")
	if dir:
		var result = dir.copy(SAVE_PATH.get_file(), export_path)
		if result == OK:
			print("Save exported to: " + export_path)
			return true
		else:
			push_error("Failed to export save: error " + str(result))
			return false
	
	return false

func import_save(import_path: String) -> bool:
	# Importar save desde una ubicación específica
	if not FileAccess.file_exists(import_path):
		push_error("Import file not found: " + import_path)
		return false
	
	# Crear backup del save actual si existe
	if has_save_file():
		_create_backup()
	
	# Copiar el archivo importado
	var dir = DirAccess.open("user://")
	if dir:
		var result = dir.copy(import_path, SAVE_PATH.get_file())
		if result == OK:
			print("Save imported from: " + import_path)
			# Intentar cargar el save importado
			return load_game()
		else:
			push_error("Failed to import save: error " + str(result))
			return false
	
	return false
