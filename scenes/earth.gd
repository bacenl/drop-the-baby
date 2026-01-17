extends Node2D

var ROTATION_SPEED = 0.05
var theta_rad = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	rotation -= delta * ROTATION_SPEED # Counter-clockwise
