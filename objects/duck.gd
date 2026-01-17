class_name Duck
extends Node2D

var BASE_SPEED: float = 10
var BABY_CAPACITY: float = 5
var VERTICAL_ACCELERATION: float = 500
var MIN_RADIUS: float = 150
var MAX_RADIUS: float = 250

var curr_radius: float
var curr_speed: float
var theta_rad: float = 0

var local_x_offset_array = [-5, -5, -10, -15, -25]
var y_offset = -20
var local_y_offset_array = [y_offset, y_offset * 2, y_offset * 3, y_offset * 4, y_offset * 5]
var baby_array: Array[Baby]= []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(0, -MIN_RADIUS)
	curr_radius = MIN_RADIUS
	curr_speed = BASE_SPEED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Global.is_playing():
		return
	_handle_input(delta)
	print("Score: ", Global.score)
	print("Rep: ", Global.reputation)


	rotation = theta_rad
	theta_rad += curr_speed / curr_radius # omega = v/r, theta = theta_0 + d_omega * t
	position.x = curr_radius * sin(theta_rad)
	position.y = -curr_radius * cos(theta_rad)


func add_baby(baby: Baby) -> void:
	if baby_array.size() >= BABY_CAPACITY:
		return

	baby_array.append(baby)
	baby.get_parent().remove_child(baby)
	self.add_child(baby)
	baby.add_to_group("duck")

	baby.is_falling = false
	baby.is_collected = true

	print(baby_array)
	_update_baby_positions()


func _drop_baby() -> void:
	if baby_array.is_empty():
		return

	var baby = baby_array.pop_front()
	var global_pos = baby.global_position
	self.remove_child(baby)
	self.get_parent().add_child(baby)
	baby.remove_from_group("duck")

	baby.is_falling = true
	baby.fall_direction = Global.CENTER - global_pos
	baby.fall_speed = 2

	_update_baby_positions()
	print(baby_array)
	baby.position = global_pos


func _update_baby_positions() -> void:
	for i in range(baby_array.size()):
		baby_array[i].position = Vector2(local_x_offset_array[i],local_y_offset_array[i])


func _handle_input(delta: float) -> void:
	if Input.is_action_pressed("accelerate"):
		curr_radius = clamp(curr_radius - VERTICAL_ACCELERATION * delta, MIN_RADIUS, MAX_RADIUS)
	else:
		curr_radius = clamp(curr_radius + VERTICAL_ACCELERATION * delta, MIN_RADIUS, MAX_RADIUS)

	if Input.is_action_just_pressed("drop"):
		_drop_baby()
