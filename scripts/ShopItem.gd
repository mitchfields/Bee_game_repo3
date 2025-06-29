# res://scripts/ShopItem.gd
extends Node2D

@export var spawn_scene: PackedScene
@export var icon_size: Vector2 = Vector2(64, 64)

var _dragging: bool = false
var frozen: bool    = false

func _ready() -> void:
	# scale the placeholder sprite if it already has a texture
	var sprite = $Sprite2D
	if sprite.texture:
		var tex_sz = sprite.texture.get_size()
		if tex_sz.x > 0:
			var scale_factor = icon_size.x / tex_sz.x
			sprite.scale = Vector2(scale_factor, scale_factor)

func update_icon() -> void:
	# instantiate the scene just long enough to grab its Sprite2D texture
	if not spawn_scene:
		return
	var tmp = spawn_scene.instantiate() as Node2D
	if tmp.has_node("Sprite2D"):
		var src = tmp.get_node("Sprite2D") as Sprite2D
		if src.texture:
			$Sprite2D.texture = src.texture
	# clean up
	tmp.queue_free()
	# re-scale to fit
	var tex_sz = $Sprite2D.texture.get_size()
	if tex_sz.x > 0:
		var scale_factor = icon_size.x / tex_sz.x
		$Sprite2D.scale = Vector2(scale_factor, scale_factor)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var local = to_local(event.position)
		var hit_rect = Rect2(-icon_size * 0.5, icon_size)

		# Right‐click: toggle frozen
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and hit_rect.has_point(local):
			frozen = not frozen
			modulate = Color(0.7, 0.7, 1) if frozen else Color(1, 1, 1)
			return

		# Left‐click: start/stop drag
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and hit_rect.has_point(local):
				_dragging = true
				modulate = Color(1,1,1,0.7)
			elif not event.pressed and _dragging:
				_dragging = false
				modulate = Color(0.7,0.7,1) if frozen else Color(1,1,1)
				get_parent()._on_item_dropped(self, event.position)
				return

	elif _dragging and event is InputEventMouseMotion:
		global_position = event.position
