# res://scripts/World.gd
extends Node2D

@export var queen_scene    : PackedScene
@export var hex_tile_scene : PackedScene
@export var hex_size       : float = 50.0

var _dragging_preview : Node2D     = null
var _dragging_scene   : PackedScene = null
var _panning          : bool        = false

@onready var camera       : Camera2D = $Camera2D
@onready var wave_manager = get_node("GameLayer/WaveManager") as Node

func _ready() -> void:
	var q = _spawn_queen()
	if q:
		camera.make_current()
		camera.global_position = q.position

func _input(event: InputEvent) -> void:
	# Zoom & start/stop panning
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				camera.zoom *= Vector2(1.1,1.1); return
			MOUSE_BUTTON_WHEEL_DOWN:
				camera.zoom *= Vector2(0.9,0.9); return
			MOUSE_BUTTON_MIDDLE:
				_panning = true; return
	if event is InputEventMouseButton and not event.pressed \
			and event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = false; return

	# Drag‐preview
	if _dragging_preview:
		if event is InputEventMouseMotion:
			_dragging_preview.global_position = get_global_mouse_position()
		elif event is InputEventMouseButton \
			 and event.button_index == MOUSE_BUTTON_LEFT \
			 and not event.pressed:
			var drop_y   = get_global_mouse_position().y
			var screen_h = get_viewport().get_visible_rect().size.y
			if drop_y < screen_h * 0.9:
				_spawn_hex(_dragging_scene)
			_end_drag()
		return

	# Middle‐mouse panning
	if event is InputEventMouseMotion and _panning:
		camera.global_position -= event.relative / camera.zoom
		return

func _spawn_queen() -> Node2D:
	if queen_scene == null:
		push_error("World.gd: queen_scene not assigned!")
		return null
	var q = queen_scene.instantiate() as Node2D
	q.position = axial_to_world(Vector2.ZERO)
	add_child(q)
	return q

func start_drag(scene_to_spawn: PackedScene) -> void:
	if _dragging_preview:
		_dragging_preview.queue_free()
	_dragging_scene   = scene_to_spawn
	_dragging_preview = scene_to_spawn.instantiate() as Node2D
	add_child(_dragging_preview)
	_dragging_preview.modulate = Color(1,1,1,0.6)
	_dragging_preview.scale    = Vector2(0.8,0.8)
	_dragging_preview.z_index  = 999

func _spawn_hex(scene: PackedScene) -> void:
	# 1) Compute drop coord
	var wp    = get_global_mouse_position()
	var axial = world_to_axial(wp)
	var snap  = axial_to_world(axial)

	# 2) Test “what if” we blocked this hex?
	var skip_tiles = [axial]
	var any_open = false
	var R = wave_manager.cluster_radius
	for i in range(6):
		var ang = i * (TAU / 6.0)
		var ow  = Vector2(cos(ang), sin(ang)) * R
		var oa  = world_to_axial(ow)
		# bounded A* via skip_tiles
		if not GridManager.find_path(oa, Vector2.ZERO, skip_tiles).is_empty():
			any_open = true
			break

	if not any_open:
		# full‐block: cancel placement
		_end_drag()
		return

	# 3) Commit actual tile
	var h = scene.instantiate() as Node2D
	h.axial_coords = axial
	h.position     = snap
	add_child(h)
	GridManager.register_tile(h)
	if h.has_method("play_placement_ripple"):
		h.play_placement_ripple()

func _end_drag() -> void:
	if _dragging_preview:
		_dragging_preview.queue_free()
	_dragging_preview = null
	_dragging_scene   = null

# — Hex‐grid helpers —

func axial_to_cube(a: Vector2) -> Vector3:
	return Vector3(a.x, -a.x - a.y, a.y)

func cube_to_axial(c: Vector3) -> Vector2:
	return Vector2(c.x, c.z)

func cube_round(c: Vector3) -> Vector3:
	var rx = round(c.x)
	var ry = round(c.y)
	var rz = round(c.z)
	var dx = abs(rx - c.x)
	var dy = abs(ry - c.y)
	var dz = abs(rz - c.z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector3(rx, ry, rz)

func world_to_axial(w: Vector2) -> Vector2:
	var q = (2.0/3.0 * w.x) / hex_size
	var r = ((-1.0/3.0 * w.x) + (sqrt(3)/3.0 * w.y)) / hex_size
	return cube_to_axial(cube_round(axial_to_cube(Vector2(q, r))))

func axial_to_world(a: Vector2) -> Vector2:
	var x = hex_size * 1.5 * a.x
	var y = hex_size * sqrt(3.0) * (a.y + a.x * 0.5)
	return Vector2(x, y)
