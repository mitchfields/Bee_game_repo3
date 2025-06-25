# res://scripts/World.gd
extends Node2D

@export var queen_scene    : PackedScene
@export var hex_tile_scene : PackedScene
@export var hex_size       : float       = 50.0

# Offset that represents the center of the hex grid in screen
# coordinates.  It is initialised in `_ready()` using the
# viewport size so that axial (0,0) aligns with the screen
# centre.
var grid_origin: Vector2 = Vector2.ZERO

var _dragging_preview: Node2D     = null
var _dragging_scene  : PackedScene = null

func _ready() -> void:
        # Determine the centre of the viewport so that the grid
        # origin aligns with the middle of the screen.
        grid_origin = get_viewport().get_visible_rect().size * 0.5
        # Spawn the Queen into the centre hex
        _spawn_queen()

func _spawn_queen() -> void:
	if queen_scene == null:
		push_error("World.gd: queen_scene not assigned!")
		return
	var queen = queen_scene.instantiate() as Node2D
	# Place on the (0,0) hex cell:
	queen.position = axial_to_world(Vector2.ZERO)
	add_child(queen)
	# (Optional) register with GridManager if you want it in the grid:
	# GridManager.register_tile(queen)

func start_drag(scene_to_spawn: PackedScene) -> void:
	if _dragging_preview:
		_dragging_preview.queue_free()
	_dragging_scene   = scene_to_spawn
	_dragging_preview = scene_to_spawn.instantiate() as Node2D
	add_child(_dragging_preview)
	_dragging_preview.modulate = Color(1, 1, 1, 0.6)
	_dragging_preview.scale    = Vector2(0.8, 0.8)
	_dragging_preview.z_index  = 999

func _input(event: InputEvent) -> void:
	if _dragging_preview:
		if event is InputEventMouseMotion:
			_dragging_preview.global_position = get_global_mouse_position()
		elif event is InputEventMouseButton \
				and event.button_index == MOUSE_BUTTON_LEFT \
				and not event.pressed:
			var drop_pos = get_global_mouse_position()
			var screen_h = get_viewport().get_visible_rect().size.y
			if drop_pos.y < screen_h * 0.9:
				_spawn_hex(_dragging_scene)
			_end_drag()
		return

func _spawn_hex(scene: PackedScene) -> void:
	var world_pos = get_global_mouse_position()
	var axial     = world_to_axial(world_pos)
	var snap_pos  = axial_to_world(axial)
	var new_hex   = scene.instantiate() as Node2D
	new_hex.set("axial_coords", axial)
	new_hex.position = snap_pos
	add_child(new_hex)
	GridManager.register_tile(new_hex)

func _end_drag() -> void:
	if _dragging_preview:
		_dragging_preview.queue_free()
	_dragging_preview = null
	_dragging_scene   = null

func axial_to_cube(axial: Vector2) -> Vector3:
	return Vector3(axial.x, -axial.x - axial.y, axial.y)

func cube_to_axial(cube: Vector3) -> Vector2:
	return Vector2(cube.x, cube.z)

func cube_round(cube: Vector3) -> Vector3:
	var rx = round(cube.x)
	var ry = round(cube.y)
	var rz = round(cube.z)
	var x_diff = abs(rx - cube.x)
	var y_diff = abs(ry - cube.y)
	var z_diff = abs(rz - cube.z)
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector3(rx, ry, rz)

func world_to_axial(world: Vector2) -> Vector2:
        # Convert from world coordinates (screen space) into axial
        # coordinates.  `grid_origin` is subtracted so that the
        # centre of the screen maps to axial (0,0).
        world -= grid_origin
        var q = (2.0 / 3.0 * world.x) / hex_size
        var r = ((-1.0 / 3.0 * world.x) + (sqrt(3) / 3.0 * world.y)) / hex_size
	var cube    = axial_to_cube(Vector2(q, r))
	var rounded = cube_round(cube)
	return cube_to_axial(rounded)

func axial_to_world(axial: Vector2) -> Vector2:
        # Convert axial coordinates back into world space, then
        # apply `grid_origin` so that (0,0) appears in the screen
        # centre.
        var x = hex_size * 1.5 * axial.x
        var y = hex_size * sqrt(3) * (axial.y + axial.x * 0.5)
        return Vector2(x, y) + grid_origin
