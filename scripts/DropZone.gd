extends Control

func can_drop_data(_pos: Vector2, data) -> bool:
	if data is PackedScene:
		print("✅ can_drop_data")
		return true
	return false

func drop_data(_pos: Vector2, data) -> void:
	print("📥 drop_data")
	get_tree().current_scene.spawn_hex_from_screen(
		get_viewport().get_mouse_position(), data)
