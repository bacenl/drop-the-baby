class_name BabyEffect
extends Node2D

@onready var bad: Sprite2D = $Bad
@onready var good: Sprite2D = $Good
@onready var sea: Sprite2D = $Sea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

static var baby_effect_scene = preload("res://objects/baby_effect.tscn")

var linked_baby: Baby
var outcome: BabyOutcomes

enum BabyOutcomes {
	Sea,
	Burn,
	Good,
	Bad
}

static func spawn_baby_effect(baby_outcome: BabyOutcomes, baby: Baby = null):
	var instance = baby_effect_scene.instantiate()
	instance.linked_baby = baby
	instance.outcome = baby_outcome
	return instance


func _ready() -> void:
	top_level = true

	if outcome == BabyOutcomes.Good:
		good.visible = true
	elif outcome == BabyOutcomes.Bad:
		bad.visible = true
	elif outcome == BabyOutcomes.Sea:
		sea.visible = true

	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("baby_effect_animation")


func _process(_delta: float) -> void:
	if linked_baby and is_instance_valid(linked_baby):
		global_position = linked_baby.global_position


func _on_animation_finished(_anim_name: String) -> void:
	if linked_baby:
		linked_baby.queue_free()
	queue_free()
