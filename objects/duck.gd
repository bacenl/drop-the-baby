class_name Duck
extends Node2D

var BASE_SPEED: float = 8
var BABY_CAPACITY: float = 5
var VERTICAL_ACCELERATION: float = 500
var MIN_RADIUS: float = 150
var MAX_RADIUS: float = 265

var curr_radius: float
var curr_speed: float
var theta_rad: float = 0

var local_x_offset_array = [-5, -5, -10, -15, -25]
var y_offset = -20
var local_y_offset_array = [y_offset, y_offset * 2, y_offset * 3, y_offset * 4, y_offset * 5]
var baby_array: Array[Baby]= []

@onready var jail: Node2D = $Jail
@onready var jail_animation: AnimationPlayer = $Jail/AnimationPlayer
@onready var line: Line2D = $Line2D

var TRAIL_POINT_COUNT: int = 30
var TRAIL_POINT_LIFETIME: float = 0.5
var trail_points: Array[Dictionary] = []  # {position: Vector2, age: float}
var trail_fading: bool = false

func _ready() -> void:
	position = Vector2(0, -MIN_RADIUS)
	curr_radius = MIN_RADIUS
	curr_speed = BASE_SPEED

	Global.game_ended.connect(_on_game_ended)
	Global.game_started.connect(_on_game_started)
	Global.return_to_main_menu.connect(_on_return_to_main_menu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Always update trail so it can fade out after game ends
	_update_trail(delta)

	if not Global.is_playing():
		return
	_handle_input(delta)

	rotation = theta_rad
	# speed interpolation: faster when closer (min radius), slower when farther (max radius)
	var t = (curr_radius - MIN_RADIUS) / (MAX_RADIUS - MIN_RADIUS)
	curr_speed = lerp(10.0, 8.0, t)
	theta_rad += curr_speed / curr_radius # omega = v/r, theta = theta_0 + d_omega * t
	position.x = curr_radius * sin(theta_rad)
	position.y = -curr_radius * cos(theta_rad)


func get_next_baby_target() -> int:
	if baby_array.is_empty():
		return -1
	return baby_array[0].target_zone


func add_baby(baby: Baby) -> void:
	if baby_array.size() >= BABY_CAPACITY:
		return

	Global.baby_collected.emit()

	baby_array.append(baby)
	baby.get_parent().remove_child(baby)
	self.add_child(baby)
	baby.add_to_group("duck")

	baby.is_falling = false
	baby.is_collected = true
	baby.reset_burn()

	_update_baby_positions()
	Global.update_next_duck.emit(get_next_baby_target())
	Global.capacity_changed.emit(baby_array.size())


func _drop_baby() -> void:
	if baby_array.is_empty():
		return

	Global.baby_dropped.emit()

	var baby = baby_array.pop_front()
	var global_pos = baby.global_position
	self.remove_child(baby)
	self.get_parent().add_child(baby)
	baby.remove_from_group("duck")

	baby.is_falling = true
	baby.fall_direction = Global.CENTER - global_pos
	baby.fall_speed = 2
	baby.position = global_pos

	Global.update_next_duck.emit(get_next_baby_target())
	Global.capacity_changed.emit(baby_array.size())
	_update_baby_positions()


func _update_baby_positions() -> void:
	# Filter out any freed babies first
	baby_array = baby_array.filter(func(baby): return is_instance_valid(baby))
	for i in range(baby_array.size()):
		baby_array[i].position = Vector2(local_x_offset_array[i],local_y_offset_array[i])


func _handle_input(delta: float) -> void:
	if Input.is_action_pressed("accelerate"):
		curr_radius = clamp(curr_radius - VERTICAL_ACCELERATION * delta, MIN_RADIUS, MAX_RADIUS)
	else:
		curr_radius = clamp(curr_radius + VERTICAL_ACCELERATION * delta, MIN_RADIUS, MAX_RADIUS)

	if Input.is_action_just_pressed("drop"):
		_drop_baby()


func _on_game_ended(_score: int) -> void:
	_drop_all_babies.call_deferred()
	jail.show()
	jail_animation.play("jail_duck")
	trail_fading = true


func _drop_all_babies() -> void:
	while not baby_array.is_empty():
		var baby = baby_array.pop_front()
		var global_pos = baby.global_position
		self.remove_child(baby)
		self.get_parent().add_child(baby)
		baby.remove_from_group("duck")
		baby.position = global_pos
		baby.is_falling = true
		baby.fall_direction = Global.CENTER - global_pos
		baby.fall_speed = 2


func _on_game_started() -> void:
	jail.hide()
	jail_animation.stop()
	trail_points.clear()
	line.points = []
	trail_fading = false


func _on_return_to_main_menu() -> void:
	jail.hide()
	jail_animation.stop()


func _update_trail(delta: float) -> void:
	# Only add new points when not fading
	if not trail_fading:
		trail_points.push_front({"position": global_position, "age": 0.0})

		# Limit the number of stored positions
		if trail_points.size() > TRAIL_POINT_COUNT:
			trail_points.resize(TRAIL_POINT_COUNT)

	# Age all points and remove expired ones
	for i in range(trail_points.size() - 1, -1, -1):
		trail_points[i].age += delta
		if trail_points[i].age >= TRAIL_POINT_LIFETIME:
			trail_points.remove_at(i)

	# Convert global positions to local positions (compensating for duck's rotation)
	var local_points: PackedVector2Array = []
	for point in trail_points:
		local_points.append(to_local(point.position))

	line.points = local_points
