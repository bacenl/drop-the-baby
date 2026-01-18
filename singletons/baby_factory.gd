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

	# Get spawn angle avoiding ±45 degrees of the duck's position
	var spawn_angle = _get_safe_spawn_angle()
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
	# Let babies naturally fall and die - only force clear on new game start
	pass


func _clear_all_babies() -> void:
	for baby in get_tree().get_nodes_in_group("babies"):
		baby.queue_free()
	for child in get_children():
		if child is Baby:
			child.queue_free()


func _on_score_changed(new_score: int) -> void:
	current_spawn_interval = _calculate_difficulty(new_score)


func _get_safe_spawn_angle() -> float:
	# Try to get the duck's position to avoid spawning near it
	var duck = get_tree().get_first_node_in_group("duck_player")
	if duck == null:
		# Fallback: find duck by class name
		for node in get_tree().get_nodes_in_group(""):
			if node is Duck:
				duck = node
				break

	if duck == null:
		# No duck found, spawn anywhere
		return randf_range(0, TAU)

	# Calculate duck's angle from origin (atan2 returns angle from positive X axis)
	var duck_angle = atan2(duck.global_position.y, duck.global_position.x)

	# Exclusion zone: ±45 degrees (PI/4 radians) around duck
	var exclusion_half = PI / 4.0

	# Generate angle in the safe zone (270 degrees = 3*PI/2 radians)
	var safe_range = TAU - (2 * exclusion_half)  # Total safe range
	var random_offset = randf_range(0, safe_range)

	# Start from just after the exclusion zone ends
	var spawn_angle = duck_angle + exclusion_half + random_offset

	# Normalize to [0, TAU)
	spawn_angle = fmod(spawn_angle + TAU, TAU)

	return spawn_angle
