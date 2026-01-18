extends Control

@onready var top_right: VBoxContainer = $TopRight
@onready var top_left: VBoxContainer = $TopLeft
@onready var middle: Control = $Middle

@onready var thumb_1: TextureRect = $TopRight/Reputation/Thumb1
@onready var thumb_2: TextureRect = $TopRight/Reputation/Thumb2
@onready var thumb_3: TextureRect = $TopRight/Reputation/Thumb3
@onready var thumbs: Array[TextureRect] = [thumb_1, thumb_2, thumb_3]

@onready var current_score_label: Label = $TopRight/CurrentScoreWrapper/CurrentScore
@onready var score_thumb: TextureRect = $TopRight/CurrentScoreWrapper/ScoreThumb
@onready var current_final_score_label: Label = $Middle/ColorRect/Control/CurrentFinalScore
@onready var high_score_label: Label = $Middle/ColorRect/Control/HighScore

@onready var next_duck: TextureRect = $TopLeft/CurrentScoreWrapper/NextColor
@onready var capacity_label: Label = $TopLeft/Capacity
@onready var first_in_line_label: Label = $TopLeft/FirstInLineDummyText
@onready var top_left_score_wrapper: HBoxContainer = $TopLeft/CurrentScoreWrapper

var color_textures = [
	preload("res://resources/shaders/preset_colors/color_1.tres"),
	preload("res://resources/shaders/preset_colors/color_2.tres"),
	preload("res://resources/shaders/preset_colors/color_3.tres"),
	preload("res://resources/shaders/preset_colors/color_4.tres"),
	preload("res://resources/shaders/preset_colors/color_5.tres"),
	preload("res://resources/shaders/preset_colors/color_6.tres"),
]

var _score_scale_material: ShaderMaterial = preload("res://resources/shaders/ui_scale_material.tres")
var _thumb_scale_material: ShaderMaterial
var _can_restart := false
var _previous_reputation := 0


func _ready() -> void:
	Global.game_started.connect(_on_game_started)
	Global.game_ended.connect(_on_game_ended)
	Global.score_changed.connect(_on_score_changed)
	Global.reputation_changed.connect(_on_reputation_changed)
	Global.return_to_main_menu.connect(_on_return_to_main_menu)

	Global.update_next_duck.connect(_on_update_next_duck)
	Global.capacity_changed.connect(_on_capacity_changed)

	# Initial state: hide all until game starts
	top_right.hide()
	top_left.hide()
	middle.hide()


func _on_game_started() -> void:
	_can_restart = false
	_previous_reputation = Global.MAX_REPUTATION
	middle.hide()
	top_right.show()
	top_left.show()
	current_score_label.text = "0"
	_update_reputation(Global.MAX_REPUTATION)
	_on_capacity_changed(0)


func _on_game_ended(_final_score: int) -> void:
	# top_right.hide()
	top_left.hide()

	var score := Global.score
	var high := Global.high_score

	current_final_score_label.text = "Score: %d" % score

	if score >= high:
		high_score_label.text = "New high score!"
	else:
		high_score_label.text = "High Score: %d" % high

	# Fade in the middle overlay
	middle.modulate.a = 0.0
	middle.show()
	var tween = create_tween()
	tween.tween_property(middle, "modulate:a", 1.0, 0.5)
	tween.finished.connect(func(): _can_restart = true)


func _on_score_changed(new_score: int) -> void:
	current_score_label.text = str(new_score)
	_animate_score_pop()


func _on_reputation_changed(new_reputation: int) -> void:
	if new_reputation < _previous_reputation:
		_animate_health_pop(new_reputation)
	_previous_reputation = new_reputation
	_update_reputation(new_reputation)


func _update_reputation(reputation: int) -> void:
	for i in range(thumbs.size()):
		thumbs[i].visible = i < reputation


func _on_return_to_main_menu() -> void:
	top_right.hide()
	top_left.hide()
	middle.hide()


func _on_update_next_duck(target: int) -> void:
	if target == -1:
		next_duck.visible = false
		return
	next_duck.visible = true
	next_duck.material = color_textures[target - 1]


func _on_capacity_changed(count: int) -> void:
	capacity_label.text = "Capacity: %d / 5" % count
	var show_elements = count > 0
	first_in_line_label.visible = show_elements
	top_left_score_wrapper.visible = show_elements


func _animate_score_pop() -> void:
	var scale_amount := 1.3
	var duration := 0.15

	# Apply shader material for scale effect (works around container layout limitations)
	current_score_label.material = _score_scale_material

	var tween = create_tween()
	tween.tween_property(_score_scale_material, "shader_parameter/scale", scale_amount, duration)
	tween.tween_property(_score_scale_material, "shader_parameter/scale", 1.0, duration)


func _animate_health_pop(remaining_health: int) -> void:
	var scale_amount := 1.3
	var duration := 0.15

	# Create a new material instance for the health animation
	_thumb_scale_material = preload("res://resources/shaders/ui_scale_material.tres").duplicate()

	# Apply to all remaining visible thumbs
	for i in range(remaining_health):
		thumbs[i].material = _thumb_scale_material

	var tween = create_tween()
	tween.tween_property(_thumb_scale_material, "shader_parameter/scale", scale_amount, duration)
	tween.tween_property(_thumb_scale_material, "shader_parameter/scale", 1.0, duration)


func _input(event: InputEvent) -> void:
	if Global.is_game_over() and _can_restart:
		if event.is_action_pressed("accelerate"):
			Global.start_game()
		elif event.is_action_pressed("ui_cancel"):
			Global.go_to_main_menu()
