extends Control

@onready var top_right: VBoxContainer = $TopRight
@onready var middle: Control = $Middle

@onready var thumb_1: TextureRect = $TopRight/Reputation/Thumb1
@onready var thumb_2: TextureRect = $TopRight/Reputation/Thumb2
@onready var thumb_3: TextureRect = $TopRight/Reputation/Thumb3
@onready var thumbs: Array[TextureRect] = [thumb_1, thumb_2, thumb_3]

@onready var current_score_label: Label = $TopRight/CurrentScoreWrapper/CurrentScore
@onready var current_final_score_label: Label = $Middle/Control/CurrentFinalScore
@onready var high_score_label: Label = $Middle/Control/HighScore

@onready var next_duck: TextureRect = $TopLeft/CurrentScoreWrapper/NextColor

var color_textures = [
	preload("res://resources/shaders/preset_colors/color_1.tres"),
	preload("res://resources/shaders/preset_colors/color_2.tres"),
	preload("res://resources/shaders/preset_colors/color_3.tres"),
	preload("res://resources/shaders/preset_colors/color_4.tres"),
	preload("res://resources/shaders/preset_colors/color_5.tres"),
	preload("res://resources/shaders/preset_colors/color_6.tres"),
]


func _ready() -> void:
	Global.game_started.connect(_on_game_started)
	Global.game_ended.connect(_on_game_ended)
	Global.score_changed.connect(_on_score_changed)
	Global.reputation_changed.connect(_on_reputation_changed)
	Global.return_to_main_menu.connect(_on_return_to_main_menu)

	Global.update_next_duck.connect(_on_update_next_duck)

	# Initial state: hide both until game starts
	top_right.hide()
	middle.hide()


func _on_game_started() -> void:
	middle.hide()
	top_right.show()
	current_score_label.text = "0"
	_update_reputation(Global.MAX_REPUTATION)


func _on_game_ended(_final_score: int) -> void:
	top_right.hide()

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


func _on_score_changed(new_score: int) -> void:
	current_score_label.text = str(new_score)


func _on_reputation_changed(new_reputation: int) -> void:
	_update_reputation(new_reputation)


func _update_reputation(reputation: int) -> void:
	for i in range(thumbs.size()):
		thumbs[i].visible = i < reputation


func _on_return_to_main_menu() -> void:
	top_right.hide()
	middle.hide()


func _on_update_next_duck(target: int) -> void:
	print("next: " + str(target))
	if target == -1:
		next_duck.visible = false
		return
	next_duck.visible = true
	next_duck.material = color_textures[target - 1]


func _input(event: InputEvent) -> void:
	if Global.is_game_over():
		if event.is_action_pressed("accelerate"):
			Global.start_game()
		elif event.is_action_pressed("ui_cancel"):
			Global.go_to_main_menu()
