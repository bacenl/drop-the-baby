extends Node2D

var score = 0

func score_baby(baby: Baby) -> void:
	if baby.in_correct_zone:
		score += 1
	else:
		score -= 1
	print(score)
