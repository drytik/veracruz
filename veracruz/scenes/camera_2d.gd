extends Camera2D

## Zoom variables 

var max_zoom : Vector2 = Vector2(3,3)
var min_zoom : Vector2 = Vector2(1,1)
var zoom_speed : float = 10
var zoomTarget : Vector2

## Move variables

var move_speed : int = 1000

func _ready() -> void:
	zoomTarget = zoom
	
func _process(delta: float) -> void:
	_zoom_camera(delta)
	_move_camera(delta)
	_debug()

func _zoom_camera(delta):
	
	if Input.is_action_pressed("zoom_in") and zoomTarget >= min_zoom:
		zoomTarget *= 1.01
	if Input.is_action_pressed("zoom_out") and zoomTarget <= max_zoom: 
		zoomTarget *= 0.99
		
	zoomTarget = zoomTarget.clamp(min_zoom, max_zoom)
	zoom = zoom.lerp(zoomTarget, zoom_speed * delta)
	
func _move_camera(delta):
	
	var moveAmount : Vector2 = Vector2.ZERO
	
	if zoomTarget > min_zoom:
		if Input.is_action_pressed("move_right") and position.x < 1440: 
			moveAmount.x += 1
		if Input.is_action_pressed("move_left") and position.x > 480: 
			moveAmount.x -= 1
		if Input.is_action_pressed("move_up") and position.y > 405: 
			moveAmount.y -= 1
		if Input.is_action_pressed("move_down") and position.y < 810:
			moveAmount.y += 1

		moveAmount = moveAmount.normalized()
		position += moveAmount * delta * move_speed * (1/zoom.x)
	
	
func _debug(): 
	print (position)
