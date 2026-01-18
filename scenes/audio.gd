extends Node2D



@onready var bgm_player: AudioStreamPlayer2D
@onready var sfx_players: Array[AudioStreamPlayer2D] = []

const MAX_SFX_PLAYERS = 8  # Maximum number of simultaneous sound effects
const SFX_FADE_OUT_DURATION = 5.0  # Duration in seconds for SFX fade out

var is_fading_sfx = false

# Audio
var main_menu_audio = load("res://resources/sounds/bgm/menu.wav")
var in_game_audio = load("res://resources/sounds/bgm/in_game.wav")

# SFX
var ocean = load("res://resources/sounds/sfx/ocean.wav")
var burning = load("res://resources/sounds/sfx/burning.wav")
var collect = load("res://resources/sounds/sfx/collect.wav")
var drop = load("res://resources/sounds/sfx/drop.wav")
var success = load("res://resources/sounds/sfx/success.mp3")
var lost = load("res://resources/sounds/sfx/lost.wav")
var five_points = load("res://resources/sounds/sfx/five_points.mp3")
var game_end = load("res://resources/sounds/sfx/game_end.mp3")

func _ready() -> void:
	if not bgm_player:
		bgm_player = AudioStreamPlayer2D.new()
		bgm_player.name = "BGMPlayer"
		bgm_player.bus = "Master"
		add_child(bgm_player)
		play_bgm(main_menu_audio)

	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer2D.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	Global.game_started.connect(_on_game_started)
	Global.game_ended.connect(_on_game_ended)
	Global.baby_success.connect(_on_baby_success)
	Global.baby_collected.connect(_on_baby_collected)
	Global.baby_dropped.connect(_on_baby_dropped)
	Global.baby_land_lost.connect(_on_baby_land_lost)
	Global.baby_spawn.connect(_on_baby_spawn)
	Global.baby_ocean.connect(_on_baby_ocean)
	Global.five_points.connect(_on_five_points)


func _process(delta: float) -> void:
	if is_fading_sfx:
		_handle_sfx_fade(delta)

func _on_game_started() -> void:
	is_fading_sfx = false
	# Reset volume for all SFX players
	for player in sfx_players:
		player.volume_db = 0.0
	play_bgm(in_game_audio)

func _on_game_ended(_final_score: int) -> void:
	# Start fading out all SFX
	is_fading_sfx = true
	play_sfx(game_end)
	play_bgm(main_menu_audio)

func _on_baby_spawn () -> void:
	pass

func _on_baby_success() -> void:
	play_sfx(success)

func _on_baby_collected() -> void:
	play_sfx(collect)

func _on_baby_ocean() -> void:
	play_sfx(ocean)

func _on_baby_dropped() -> void:
	play_sfx(drop)

func _on_baby_land_lost() -> void:
	play_sfx(lost)

func _on_five_points() -> void:
	play_sfx(five_points)

func play_bgm(resource: AudioStream) -> void:
	bgm_player.stream = resource
	bgm_player.play()

func play_sfx(resource: AudioStream) -> void:
	for player in sfx_players:
		if not player.playing:
			player.stream = resource
			player.play()
			return

	sfx_players[0].stream = resource
	sfx_players[0].play()

func _handle_sfx_fade(delta: float) -> void:
	var all_stopped = true

	for player in sfx_players:
		if player.playing:
			all_stopped = false
			# Fade out: decrease volume over time
			# -60 db is essentially silent
			var volume_decrease = (60.0 / SFX_FADE_OUT_DURATION) * delta
			player.volume_db -= volume_decrease

			# Stop the player if volume is very low
			if player.volume_db <= -60.0:
				player.stop()
				player.volume_db = 0.0  # Reset for next use

	# Stop fading when all players have stopped
	if all_stopped:
		is_fading_sfx = false
