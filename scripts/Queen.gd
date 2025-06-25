# res://scripts/Queen.gd
extends Node2D

@export var max_health: int = 10
var hp: int

func _ready() -> void:
	hp = max_health
	# assumes you have a TextureProgress child named "HealthBar"
	$HealthBar.max_value = max_health
	$HealthBar.value     = hp

func take_damage(amount: int) -> void:
	hp -= amount
	$HealthBar.value = hp
	if hp <= 0:
		get_tree().paused = true
		print("Game Over – Queen has fallen")
