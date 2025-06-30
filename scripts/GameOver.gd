# res://scripts/GameOver.gd
extends Control

func _ready() -> void:
	$VBoxContainer/Retry.pressed.connect(_on_retry)
	$VBoxContainer/MainMenu.pressed.connect(_on_menu)

func _on_retry() -> void:
	get_tree().change_scene("res://scenes/World.tscn")

func _on_menu() -> void:
	get_tree().change_scene("res://scenes/MainMenu.tscn")
