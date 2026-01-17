extends Camera2D

@onready var main_menu_overlay: Control = get_node_or_null("../MainMenuOverlayCanvas/MainMenuOverlay")

var base_position: Vector2
var menu_offset: Vector2 = Vector2(0, -80)
var lerp_speed: float = 5.0

func _ready() -> void:
	base_position = position

func _process(delta: float) -> void:
	var target_position: Vector2 = base_position

	if main_menu_overlay:
		target_position = base_position + menu_offset * main_menu_overlay.modulate.a

	position = position.lerp(target_position, lerp_speed * delta)
