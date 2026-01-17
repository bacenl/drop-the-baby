class_name Earth
extends Node2D

static var CENTER: Vector2 = Vector2(0, 0)
var score = 0

func score_baby(baby: Baby) -> void:
	if baby.in_correct_zone:
		score += 1
	else:
		score -= 1
	print("score: " + str(score))
