extends Node2D

var FLYING_RADIUS: float = 150
var BASE_SPEED: float = 1
var FAST_SPEED: float = 1.5
var BABY_CAPACITY: float = 5

var curr_radius: float
var curr_speed: float
var theta_rad: float = 0
var baby_queue: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_radius = FLYING_RADIUS
	curr_speed = BASE_SPEED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_handle_input()

	rotation = theta_rad
	theta_rad += curr_speed * delta
	position.x = curr_radius * cos(theta_rad)
	position.y = curr_radius * sin(theta_rad)
	pass


func set_speed(new_speed: float) -> void:
	curr_speed = new_speed


func _handle_input() -> void:
	if Input.is_action_pressed("accelerate"):
		set_speed(FAST_SPEED)
	else:
		set_speed(BASE_SPEED)

	if Input.is_action_pressed("drop"):
		print("drop")
