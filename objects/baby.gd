class_name Baby
extends Node2D

var DEFAULT_FALL_SPEED: float = 0.5
var CENTER: Vector2 = Vector2(0, 0)

@onready
var area2d: Area2D = $'Area2D'
@onready
var duck: Duck = $'../../Duck'

var is_falling: bool = true
var fall_direction: Vector2
var fall_speed: float
var is_collected: bool = false # To determine whether dropped into a correct zone should score
var in_correct_zone: bool = false # Secondary check if duck is dropped in correct zone
var correct_zone: int = 1
enum Zone {ZONE_1, ZONE_2}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fall_direction = CENTER - position
	fall_speed = DEFAULT_FALL_SPEED

	area2d.connect("area_entered", _on_area_entered)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_falling:
		position += delta * fall_direction * fall_speed
	pass


func _kill_self() -> void:
	print("deadge")
	queue_free()

func _on_area_entered(area: Area2D):
	if not is_collected:
		if area.is_in_group("duck"):
			duck.add_baby(self)
			return
		if area.is_in_group("earth"):
			_kill_self()
			return
	
	if area.is_in_group("zones"):
		# check zone correctness
		# in case collides with multiple areas
		in_correct_zone = in_correct_zone or area.check_zone() == correct_zone
		
	# Handle collisions here
	# If not collected, check against the whole earth
	# If collected, and if correct zone, score
	# else, die
	if area.is_in_group("earth") and in_correct_zone:
		area.score_baby(self)
		_kill_self()
		return
