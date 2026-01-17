class_name BabyEffect
extends Node2D

@onready var bad: Sprite2D = $Bad
@onready var good: Sprite2D = $Good
@onready var sea: Sprite2D = $Sea

static var baby_effect_scene = preload("res://objects/baby_effect.tscn")

enum BabyOutcomes {
	Sea,
	Burn,
	Good,
	Bad
}

static func spawn_baby_effect(baby_outcome: BabyOutcomes):
	var instance = baby_effect_scene.instantiate()
	if baby_outcome == BabyOutcomes.Good:
		instance.good.visible = true
	elif baby_outcome == BabyOutcomes.Bad:
		instance.bad.visible = true
	elif baby_outcome == BabyOutcomes.Sea:
		instance.sea.visible = true
	else: # burning has no animation
		pass
	return instance
