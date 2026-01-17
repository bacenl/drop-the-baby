class_name Baby
extends Node2D

var DEFAULT_FALL_SPEED: float = 0.3

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area2d.connect("area_entered", _on_area_entered)

	fall_direction = Global.CENTER - position
	fall_speed = DEFAULT_FALL_SPEED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_falling:
		position += delta * fall_direction * fall_speed


func _success() -> void:
	Global.baby_caught.emit()
	queue_free() # to replace with animations


func _lost() -> void:
	Global.baby_lost.emit()
	queue_free() # to replace with animations

func _on_area_entered(area: Area2D):
	if not is_collected:
		if area.is_in_group("duck"):
			duck.add_baby(self)
			return
		if area.is_in_group("earth"):
			_lost()
			return
	
	if area.is_in_group("zones"):
		print(area.get_groups())
		# in case collides with multiple areas
		print(area, area.has_method("check_zone"))
		in_correct_zone = in_correct_zone or area.check_zone() == correct_zone
		if in_correct_zone:
			_success()
			return
		
	if area.is_in_group("earth"):
		_lost()
		return
