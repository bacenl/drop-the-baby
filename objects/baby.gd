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

var fire_material = preload("res://resources/shaders/fire_material.tres")

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

var is_burning: bool = false
var burn_material: ShaderMaterial
var is_resolved: bool = false

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
		_update_burning()
		_update_rotation()
	_sample_line_texture()


func _update_rotation() -> void:
	# Rotate so baby's bottom faces the earth (center)
	# atan2 gives angle from positive X axis, we add PI/2 to make bottom point toward center
	rotation = position.angle() + PI / 2


func _update_burning() -> void:
	# Only un-caught babies can burn
	if is_collected:
		return

	var distance_from_center = position.length()

	# Start burning when past duck's max radius
	if distance_from_center < duck.MAX_RADIUS and not is_burning:
		is_burning = true
		var original_material = sprite.material
		burn_material = fire_material.duplicate()
		# Copy tint parameters from original material
		burn_material.set_shader_parameter("original_color_weight", original_material.get_shader_parameter("original_color_weight"))
		burn_material.set_shader_parameter("tint_color", original_material.get_shader_parameter("tint_color"))
		burn_material.set_shader_parameter("tolerance", original_material.get_shader_parameter("tolerance"))
		burn_material.set_shader_parameter("blacklist_color_1", original_material.get_shader_parameter("blacklist_color_1"))
		burn_material.set_shader_parameter("blacklist_color_2", original_material.get_shader_parameter("blacklist_color_2"))
		burn_material.set_shader_parameter("blacklist_color_3", original_material.get_shader_parameter("blacklist_color_3"))
		burn_material.set_shader_parameter("blacklist_color_4", original_material.get_shader_parameter("blacklist_color_4"))
		burn_material.set_shader_parameter("blacklist_color_5", original_material.get_shader_parameter("blacklist_color_5"))
		burn_material.set_shader_parameter("blacklist_color_6", original_material.get_shader_parameter("blacklist_color_6"))
		sprite.material = burn_material

	if is_burning:
		# Calculate burn progress: 1.0 at MAX_RADIUS, 0.0 at origin
		var burn_progress = clamp(distance_from_center / duck.MAX_RADIUS, 0.0, 1.0)
		burn_material.set_shader_parameter("y_position_2", burn_progress)
		burn_material.set_shader_parameter("transparency", 1.0)
	

func _set_target_zone() -> void:
	target_zone = rng.randi_range(1, 6)
	sprite.material = color_textures[target_zone - 1]


func reset_burn() -> void:
	if is_burning:
		is_burning = false
		sprite.material = color_textures[target_zone - 1]
		burn_material = null


func _sample_line_texture() -> void:
	line.points = [Vector2.ZERO, Vector2(0, -fall_direction.length())]


func _success() -> void:
	if is_resolved:
		return
	is_resolved = true
	Global.baby_success.emit()
	is_falling = false
	if is_collected:
		_reparent_to_earth.call_deferred()
		_spawn_effect.call_deferred(BabyEffect.BabyOutcomes.Good)
	else:
		queue_free.call_deferred()


func _lost() -> void:
	if is_resolved:
		return
	is_resolved = true
	Global.baby_lost.emit()
	is_falling = false
	if is_collected:
		_reparent_to_earth.call_deferred()
		if current_zone == 0:
			_spawn_effect.call_deferred(BabyEffect.BabyOutcomes.Sea)
		else:
			_spawn_effect.call_deferred(BabyEffect.BabyOutcomes.Bad)
	elif is_burning and burn_material:
		_reparent_to_earth.call_deferred()
		burn_material.set_shader_parameter("y_position_2", 0.0)
		_fade_out()
	else:
		queue_free.call_deferred()


func _spawn_effect(outcome: BabyEffect.BabyOutcomes) -> void:
	var effect = BabyEffect.spawn_baby_effect(outcome, self)
	add_child(effect)


func _reparent_to_earth() -> void:
	var earth = get_tree().get_first_node_in_group("earth").get_parent()
	var global_pos = global_position
	var global_rot = global_rotation
	get_parent().remove_child(self)
	earth.add_child(self)
	global_position = global_pos
	global_rotation = global_rot


func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_method(_set_burn_transparency, 1.0, 0.0, 0.5)
	tween.tween_callback(queue_free)


func _set_burn_transparency(value: float) -> void:
	if burn_material:
		burn_material.set_shader_parameter("transparency", value)

func _on_area_entered(area: Area2D):
	if area.is_in_group("earth"):
		if current_zone == target_zone and is_collected:
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
		return
