# res://scripts/SelectionManager.gd
extends Node2D

var selected = []
var _dragging_tiles = []
var _drag_offset = Vector2.ZERO
var _rect_start = Vector2.ZERO
var _rect_selecting = false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.shift:
				_toggle_tile_under_mouse()
			elif event.control:
				_toggle_tile_under_mouse(true)
			else:
				_rect_start = event.position
				_rect_selecting = true
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if _rect_selecting:
				_select_in_rect(Rect2(_rect_start, event.position - _rect_start))
				_rect_selecting = false
			elif _dragging_tiles.size() > 0:
				_end_move(event.position)
	elif event is InputEventMouseMotion:
		if _rect_selecting:
			# draw selection rect if you want
			pass
		elif _dragging_tiles.size() > 0:
			_move_selected(event.position)

func _toggle_tile_under_mouse(remove=false):
	var world = get_tree().current_scene
	var ax = world.world_to_axial(world.get_global_mouse_position())
	if GridManager.tiles.has(ax):
		var tile = GridManager.tiles[ax]
		if remove:
			if selected.has(tile):
				selected.erase(tile)
				tile.set_selected(false)
		else:
			if not selected.has(tile):
				selected.append(tile)
				tile.set_selected(true)

func _select_in_rect(rect):
	for t in selected:
		t.set_selected(false)
	selected.clear()
	var world = get_tree().current_scene
	for tile in GridManager.tiles.values():
		if rect.has_point(tile.global_position):
			selected.append(tile)
			tile.set_selected(true)

func start_move():
	if selected.empty():
		return
	_dragging_tiles = selected.duplicate()
	_drag_offset = get_tree().current_scene.get_global_mouse_position() - _dragging_tiles[0].position

func _move_selected(pos):
	for t in _dragging_tiles:
		t.global_position = pos - _drag_offset

func _end_move(pos):
	var world = get_tree().current_scene
	for t in _dragging_tiles:
		world._spawn_hex(t.get_scene())
		t.queue_free()
	_dragging_tiles.clear()
