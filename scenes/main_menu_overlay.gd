extends Control

@onready var animation_player: AnimationPlayer = $ControlsGroup/AnimationPlayer


func _ready() -> void:
	Global.game_started.connect(_on_game_started)
	Global.return_to_main_menu.connect(_on_return_to_main_menu)
	animation_player.play("main_menu_in")


func _input(event: InputEvent) -> void:
	if Global.in_main_menu and event.is_action_pressed("accelerate"):
		Global.start_game()


func _on_game_started() -> void:
	# Only play fade out if we're coming from the main menu
	if modulate.a > 0:
		animation_player.play("main_menu_out")


func _on_return_to_main_menu() -> void:
	animation_player.play("main_menu_in")
