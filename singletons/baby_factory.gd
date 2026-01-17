extends Node2D

var DEFAULT_SPAWN_INTERVAL: float = 3
var baby_resource = preload("res://objects/baby.tscn")
var MIN_SPAWN_RADIUS: float = 350

var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not Global.is_playing():
		return
	timer += delta
	if (timer >= DEFAULT_SPAWN_INTERVAL):
		timer = 0
		_spawn_baby()


func _spawn_baby() -> void:
	var instance = baby_resource.instantiate()

	var rng = RandomNumberGenerator.new()
	var spawn_deg = rng.randf_range(0, 360)
	var spawn_x = MIN_SPAWN_RADIUS * cos(spawn_deg)
	var spawn_y = MIN_SPAWN_RADIUS * sin(spawn_deg)

	instance.global_position= Vector2(spawn_x, spawn_y)
	add_child(instance)
