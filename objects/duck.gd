extends Node2D

var FLYING_RADIUS = 450
var BASE_SPEED = 1
var FAST_SPEED = 1.5

var curr_radius
var curr_speed
var theta_deg = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_radius = FLYING_RADIUS
	curr_speed = BASE_SPEED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("accelerate"):
		set_speed(FAST_SPEED)
		print("fast")
	else:
		set_speed(BASE_SPEED)
	if Input.is_action_pressed("drop"):
		print("drop")

	theta_deg += curr_speed * delta
	position.x = curr_radius * cos(theta_deg)
	position.y = curr_radius * sin(theta_deg)
	pass

func set_speed(new_speed: float) -> void:
	curr_speed = new_speed


func _input(event):
	if event.is_action_pressed("accelerate"):
		set_speed(FAST_SPEED)
		print("input way")
