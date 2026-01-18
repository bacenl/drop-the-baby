class_name Baby
extends Node2D

var DEFAULT_FALL_SPEED: float = 0.18

var color_textures = [
	preload("res://resources/shaders/preset_colors/color_1.tres"),
	preload("res://resources/shaders/preset_colors/color_2.tres"),
	preload("res://resources/shaders/preset_colors/color_3.tres"),
	preload("res://resources/shaders/preset_colors/color_4.tres"),
	preload("res://resources/shaders/preset_colors/color_5.tres"),
	preload("res://resources/shaders/preset_colors/color_6.tres"),
]

var fire_material = preload("res://resources/shaders/fire_material.tres")
var burning_sound = preload("res://resources/sounds/sfx/burning.wav")

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
var burn_audio_player: AudioStreamPlayer2D

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_stop_burn_audio()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("babies")
	area2d.connect("area_entered", _on_area_entered)
	Global.baby_spawn.emit()

	_set_target_zone()

	fall_direction = Global.CENTER - position
	fall_speed = DEFAULT_FALL_SPEED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_falling:
		_update_rotation()
		position += delta * fall_direction * fall_speed
		_update_burning()
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
		# Start burning audio at 20% volume
		burn_audio_player = AudioStreamPlayer2D.new()
		burn_audio_player.stream = burning_sound
		burn_audio_player.bus = "SFX"
		burn_audio_player.volume_db = linear_to_db(0.5)
		add_child(burn_audio_player)
		burn_audio_player.play()

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
		# Volume: 50% at MAX_RADIUS (burn_progress=1.0) to 100% at origin (burn_progress=0.0)
		# linear_to_db converts linear volume (0.0-1.0) to decibels
		var volume_linear = lerp(1.0, 0.5, burn_progress)
		burn_audio_player.volume_db = linear_to_db(volume_linear)
	

func _set_target_zone() -> void:
	target_zone = rng.randi_range(1, 6)
	sprite.material = color_textures[target_zone - 1]


func reset_burn() -> void:
	if is_burning:
		is_burning = false
		sprite.material = color_textures[target_zone - 1]
		burn_material = null
		_stop_burn_audio()


func _stop_burn_audio() -> void:
	if burn_audio_player:
		burn_audio_player.stop()
		burn_audio_player.queue_free()
		burn_audio_player = null


func _sample_line_texture() -> void:
	line.points = [Vector2.ZERO, Vector2(0, -fall_direction.length())]


func _success() -> void:
	if is_resolved:
		return
	is_resolved = true
	Global.baby_success.emit()
	is_falling = false
	line.hide()
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
	line.hide()
	if is_collected:
		_reparent_to_earth.call_deferred()
		if current_zone == 0:
			Global.baby_ocean.emit() # bad coding practice here
			_spawn_effect.call_deferred(BabyEffect.BabyOutcomes.Sea)
		else:
			Global.baby_land_lost.emit()
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
		# Max volume when touching earth
		if burn_audio_player:
			burn_audio_player.volume_db = linear_to_db(1.0)
		# Check for zone overlap before deciding it's sea
		if current_zone == 0:
			for zone in get_tree().get_nodes_in_group("zones"):
				if area2d.overlaps_area(zone):
					current_zone = zone.check_zone()
					break

		if current_zone == target_zone and is_collected:
			_success()
			return
		_lost()
		return
	
	if not is_collected:
		if area.is_in_group("duck"):
			line.hide()
			duck.add_baby.call_deferred(self)
			return
		if area.is_in_group("earth"):
			_lost()
			return
	
	if area.is_in_group("zones"):
		# dont success immediately, so duck has time to fall onto surface of earth
		# else floats sometimes
		# Track which zone the baby is in (for when it hits earth)
		if (area.check_zone() > 0):
			current_zone = area.check_zone()
		return
