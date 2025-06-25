# res://scripts/ShopItem.gd
extends Node2D

@export var spawn_scene: PackedScene
@export var icon_size: Vector2 = Vector2(64, 64)

var _dragging: bool = false
var frozen: bool = false

func _ready() -> void:
	var sprite = $Sprite2D
	var tex_sz = sprite.texture.get_size()
	if tex_sz.x > 0:
		var f = icon_size.x / tex_sz.x
		sprite.scale = Vector2(f, f)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var local = to_local(event.position)
		var hit_rect = Rect2(-icon_size * 0.5, icon_size)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and hit_rect.has_point(local):
			frozen = not frozen
			if frozen:
				modulate = Color(0.7, 0.7, 1)
			else:
				modulate = Color(1, 1, 1)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and hit_rect.has_point(local):
				_dragging = true
				modulate = Color(1, 1, 1, 0.7)
			elif not event.pressed and _dragging:
				_dragging = false
				if frozen:
					modulate = Color(0.7, 0.7, 1)
				else:
					modulate = Color(1, 1, 1)
				get_parent()._on_item_dropped(self, event.position)
				return
	elif _dragging and event is InputEventMouseMotion:
		global_position = event.position
