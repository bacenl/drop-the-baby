class_name Baby
extends Node2D

var DEFAULT_FALL_SPEED: float = 0.3

var color_textures = [
	preload("res://resources/shaders/preset_colors/color_1.tres"),
	preload("res://resources/shaders/preset_colors/color_2.tres"),
	preload("res://resources/shaders/preset_colors/color_3.tres"),
	preload("res://resources/shaders/preset_colors/color_4.tres"),
	preload("res://resources/shaders/preset_colors/color_5.tres"),
	preload("res://resources/shaders/preset_colors/color_6.tres"),
]

@onready
var sprite: Sprite2D = $'Sprite2D'
@onready
var line: Line2D = $'Line2D'
@onready
var area2d: Area2D = $'Area2D'
@onready
var duck: Duck = $'../../Duck'

var is_falling: bool = true
var fall_direction: Vector2
var fall_speed: float
var is_collected: bool = false # To determine whether dropped into a correct zone should score
var current_zone: int = 0 # Secondary check if duck is dropped in correct zone
var target_zone: int = 1
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area2d.connect("area_entered", _on_area_entered)

	_set_target_zone()

	fall_direction = Global.CENTER - position
	fall_speed = DEFAULT_FALL_SPEED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_falling:
		position += delta * fall_direction * fall_speed
	_sample_line_texture()
	

func _set_target_zone() -> void:
	target_zone = rng.randi_range(1, 6)
	sprite.material = color_textures[target_zone - 1]


func _sample_line_texture() -> void:
	line.points = [0, -fall_direction]


func _success() -> void:
	Global.baby_success.emit()
	queue_free() # to replace with animations


func _lost() -> void:
	Global.baby_lost.emit()
	queue_free() # to replace with animations
	if current_zone == 0:
		# in sea
		pass
	else:
		# on land
		pass

func _on_area_entered(area: Area2D):
	if area.is_in_group("earth"):
		if current_zone == target_zone:
			_success()
			return
		_lost()
		return
	
	if not is_collected:
		if area.is_in_group("duck"):
			Global.baby_collected.emit(self)
			line.hide()
			duck.add_baby.call_deferred(self)
			return
		if area.is_in_group("earth"):
			_lost()
			return
	
	if area.is_in_group("zones"):
		print(area.get_groups())
		# in case collides with multiple areas
		print(area, area.has_method("check_zone"))
		if current_zone == target_zone:
			_success()
			return
		
		# for land animation
		current_zone = area.check_zone()
