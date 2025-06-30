extends Control

func _ready() -> void:
	$VBoxContainer/Play.pressed.connect(_on_play_pressed)
	$VBoxContainer/Quit.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
