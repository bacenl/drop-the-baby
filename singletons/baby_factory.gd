extends Node2D

var baby_resource = preload("res://objects/baby.tscn")

# Difficulty settings
const FIRST_SPAWN_DELAY: float = 0.5    # Time before first baby spawns
const BASE_SPAWN_INTERVAL: float = 2.5  # Starting spawn interval (seconds)
const MIN_SPAWN_INTERVAL: float = 1.2   # Fastest spawn rate (remains playable)
const DIFFICULTY_SCALE_SCORE: int = 5   # Score at which difficulty is ~halfway to max

# Spawn radius - calculated to be outside screen
var spawn_radius: float = 500  # Will be recalculated in _ready

var timer: float = 0
var current_spawn_interval: float = BASE_SPAWN_INTERVAL


func _ready() -> void:
	_calculate_spawn_radius()
	Global.game_started.connect(_on_game_started)
	Global.game_ended.connect(_on_game_ended)
	Global.score_changed.connect(_on_score_changed)


func _calculate_spawn_radius() -> void:
	# Get viewport size and calculate diagonal to ensure spawns are always off-screen
	var viewport_size = get_viewport().get_visible_rect().size
	# Use half the diagonal length plus a margin to ensure babies spawn outside the visible area
	var half_diagonal = viewport_size.length() / 2.0
	spawn_radius = half_diagonal + 50  # Add margin to ensure fully off-screen


func _physics_process(delta: float) -> void:
	if not Global.is_playing():
		return
	timer += delta
	if timer >= current_spawn_interval:
		timer = 0
		_spawn_baby()


func _spawn_baby() -> void:
	var instance = baby_resource.instantiate()

	var spawn_angle = randf_range(0, TAU)  # TAU = 2*PI (full circle in radians)
	var spawn_x = spawn_radius * cos(spawn_angle)
	var spawn_y = spawn_radius * sin(spawn_angle)

	instance.global_position = Vector2(spawn_x, spawn_y)
	add_child(instance)


func _calculate_difficulty(score: int) -> float:
	# Uses an asymptotic curve: starts at BASE_SPAWN_INTERVAL, approaches MIN_SPAWN_INTERVAL
	# Formula: interval = MIN + (BASE - MIN) / (1 + score / SCALE)
	# At score 0: interval = 2.5s
	# At score 3: interval = ~2.0s (multiple babies start appearing)
	# At score 5: interval = ~1.85s (halfway point)
	# At score 15: interval = ~1.5s
	# Approaches MIN_SPAWN_INTERVAL (1.2s) asymptotically
	var interval = MIN_SPAWN_INTERVAL + (BASE_SPAWN_INTERVAL - MIN_SPAWN_INTERVAL) / (1.0 + float(score) / DIFFICULTY_SCALE_SCORE)
	return interval


func _on_game_started() -> void:
	# Clear any leftover babies from previous game
	_clear_all_babies()
	# Set timer so first baby spawns quickly
	timer = BASE_SPAWN_INTERVAL - FIRST_SPAWN_DELAY
	current_spawn_interval = BASE_SPAWN_INTERVAL


func _on_game_ended(_score: int) -> void:
	_clear_all_babies()


func _clear_all_babies() -> void:
	for child in get_children():
		if child is Baby:
			child.queue_free()


func _on_score_changed(new_score: int) -> void:
	current_spawn_interval = _calculate_difficulty(new_score)
