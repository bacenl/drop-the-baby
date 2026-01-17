extends Area2D

@export var zone_number = 0

func _ready() -> void:
	zone_number = int(str(name)[len(name) - 1])

func check_zone() -> int:
	# print(zone_number)
	return zone_number
