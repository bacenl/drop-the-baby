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
enum Zone {ZONE_1, ZONE_2}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area2d.connect("area_entered", _on_area_entered)

	fall_direction = CENTER - position
	fall_speed = DEFAULT_FALL_SPEED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_falling:
		position += delta * fall_direction * fall_speed


func _kill_self() -> void:
	print("deadge")
	queue_free()


func _on_area_entered(area: Area2D):
	if not is_collected:
		if area.is_in_group("duck"):
			duck._add_baby(self)
			return
		if area.is_in_group("earth"):
			_kill_self()
			return
	
	if area.is_in_group("zones"):
		# check zone correctness
		return
