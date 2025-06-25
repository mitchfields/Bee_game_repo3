# res://scripts/Enemy.gd
extends Node2D

signal died
signal hit_queen

@export var rarity: String = "common"  # "common","rare","epic","legendary","boss","miniboss"
var health: float
var gold_drop: int
var damage: int

func _ready() -> void:
	match rarity:
		"common":
			health = 5;  gold_drop = 1; damage = 1
		"rare":
			health = 12; gold_drop = 2; damage = 2
		"epic":
			health = 25; gold_drop = 4; damage = 3
		"legendary":
			health = 50; gold_drop = 6; damage = 4
		"miniboss":
			health = 75; gold_drop = 8; damage = 5
		"boss":
			health = 200; gold_drop = 20; damage = 10

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		emit_signal("died")
		queue_free()

func _on_reach_queen() -> void:
	# call this when pathfinding tells you you arrived
	emit_signal("hit_queen")
	queue_free()
