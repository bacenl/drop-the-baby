class_name Duck
extends Node2D

var FLYING_RADIUS: float = 150
var BASE_SPEED: float = 1
var FAST_SPEED: float = 5
var BABY_CAPACITY: float = 5

var curr_radius: float
var curr_speed: float
var theta_rad: float = 0

var local_x_offset_array = [-5, -5, -10, -15, -25]
var y_offset = -20
var local_y_offset_array = [y_offset, y_offset * 2, y_offset * 3, y_offset * 4, y_offset * 5]
var baby_array: Array[Baby]= []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_radius = FLYING_RADIUS
	curr_speed = BASE_SPEED
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_handle_input()

	rotation = theta_rad + PI/2 
	theta_rad += curr_speed * delta
	position.x = curr_radius * cos(theta_rad)
	position.y = curr_radius * sin(theta_rad)
	pass


func _set_speed(new_speed: float) -> void:
	curr_speed = new_speed


func add_baby(baby: Baby) -> void:
	if baby_array.size() >= BABY_CAPACITY:
		return
	baby.get_parent().remove_child(baby)
	self.add_child(baby)
	baby.add_to_group("duck")
	baby_array.append(baby)

	baby.is_falling = false
	baby.is_collected = true

	_update_baby_positions()
	print(baby_array)


func _drop_baby() -> void:
	if baby_array.is_empty():
		return
	var baby = baby_array.pop_front()
	self.remove_child(baby)
	self.get_parent().add_child(baby)
	baby.remove_from_group("duck")
	baby.is_falling = true
	_update_baby_positions()
	print(baby_array)


func _update_baby_positions() -> void:
	for i in range(baby_array.size()):
		baby_array[i].position = Vector2(local_x_offset_array[i],local_y_offset_array[i])


func _handle_input() -> void:
	if Input.is_action_pressed("accelerate"):
		_set_speed(FAST_SPEED)
	else:
		_set_speed(BASE_SPEED)

	if Input.is_action_just_pressed("drop"):
		_drop_baby()
		print("drop")
