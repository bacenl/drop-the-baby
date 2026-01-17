@tool
class_name OutlinedNode
extends SubViewportContainer

## Size of the viewport (should fit your content with some padding for the outline)
@export var viewport_size: Vector2i = Vector2i(128, 128):
	set(value):
		viewport_size = value
		_update_size()

## Outline color
@export var outline_color: Color = Color.WHITE:
	set(value):
		outline_color = value
		_update_shader_params()

## Outline thickness
@export_range(0.0, 100.0) var outline_thickness: float = 2.0:
	set(value):
		outline_thickness = value
		_update_shader_params()

@onready var _subviewport: SubViewport = $SubViewport
@onready var _content: Node2D = $SubViewport/Content

func _ready() -> void:
	_update_size()
	_update_shader_params()

func _update_size() -> void:
	if _subviewport:
		_subviewport.size = viewport_size
		size = Vector2(viewport_size)
		# Center the container
		position = -Vector2(viewport_size) / 2.0
		# Center content inside viewport
		if _content:
			_content.position = Vector2(viewport_size) / 2.0

func _update_shader_params() -> void:
	if material and material is ShaderMaterial:
		var mat := material as ShaderMaterial
		mat.set_shader_parameter("color", outline_color)
		mat.set_shader_parameter("thickness", outline_thickness)

## Returns the content node - add your AnimatedSprite2D children here
func get_content() -> Node2D:
	return _content
