extends Node2D
class_name World

#——— CONFIGURATION ——————————————————————————————————————————————
enum HexOrientation { POINTY, FLAT }

@export var hex_orientation : HexOrientation = HexOrientation.POINTY
@export var hex_size        : float          = 50.0   # >0!
@export var queen_scene     : PackedScene
@export var initial_spawn_distance : int      = 8
@export var player_health   : int            = 20
#———————————————————————————————————————————————————————————————————

# Drag–and–drop state
var _dragging_preview : Node2D      = null
var _dragging_scene   : PackedScene = null
var _panning          : bool        = false

# For path‐blocking checks
var _last_spawn_axial : Vector2     = Vector2.ZERO
var initial_spawn_world: Vector2

@onready var camera       : Camera2D      = $Camera2D
@onready var wave_manager = $GameLayer/WaveManager

func _ready() -> void:
	# clamp hex_size
	hex_size = max(hex_size, 0.1)
	randomize()

	# 1) spawn Queen & center camera
	var q = _spawn_queen()
	if q:
		camera.make_current()
		camera.global_position = q.position

	# 2) record a world‐space “spawn origin” for path‐checks
	initial_spawn_world = axial_to_world(Vector2(initial_spawn_distance, 0))

	# 3) hook wave_manager → enemy hit signals
	wave_manager.connect("enemy_spawned", Callable(self, "_on_enemy_spawned"))

func _on_enemy_spawned(enemy: Node2D) -> void:
	if enemy.has_signal("hit_queen"):
		enemy.connect("hit_queen", Callable(self, "_on_enemy_hit_queen"))

func _on_enemy_hit_queen(_enemy: Node2D) -> void:
	player_health -= 1
	print("Player health:", player_health)
	if player_health <= 0:
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _input(event: InputEvent) -> void:
	# — Zoom & pan —
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				camera.zoom *= Vector2(1.1, 1.1); return
			MOUSE_BUTTON_WHEEL_DOWN:
				camera.zoom *= Vector2(0.9, 0.9); return
			MOUSE_BUTTON_MIDDLE:
				_panning = true; return
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = false; return

	# — Dragging preview from shop —
	if _dragging_preview:
		if event is InputEventMouseMotion:
			_dragging_preview.global_position = get_global_mouse_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var drop_y = get_global_mouse_position().y
			var screen_h = get_viewport().get_visible_rect().size.y
			if drop_y < screen_h * 0.9:
				_spawn_hex(_dragging_scene)
			_end_drag()
		return

	# — Continue panning? —
	if _panning and event is InputEventMouseMotion:
		camera.global_position -= event.relative / camera.zoom
		return

func start_drag(scene_to_spawn: PackedScene) -> void:
	if _dragging_preview:
		_dragging_preview.queue_free()
	_dragging_scene   = scene_to_spawn
	_dragging_preview = scene_to_spawn.instantiate() as Node2D
	add_child(_dragging_preview)
	_dragging_preview.modulate = Color(1,1,1,0.6)
	_dragging_preview.scale    = Vector2(0.8,0.8)
	_dragging_preview.z_index  = 999

func _end_drag() -> void:
	if _dragging_preview:
		_dragging_preview.queue_free()
	_dragging_preview = null
	_dragging_scene   = null

func _spawn_queen() -> Node2D:
	if not queen_scene:
		push_error("World.gd: queen_scene not assigned!")
		return null
	var q = queen_scene.instantiate() as Node2D
	q.position = axial_to_world(Vector2.ZERO)
	add_child(q)
	return q

func _spawn_hex(scene: PackedScene) -> bool:
	# 1) figure out which hex we clicked
	var world_pos = get_global_mouse_position()
	var axial     = world_to_axial(world_pos)

	# 2) pick the furthest spawn‐origin for path check
	var origins = wave_manager.cluster_origins.duplicate()
	if origins.size() == 0:
		origins.append(initial_spawn_world)
	var furthest = origins[0]
	var best_d   = GridManager.distance_map.get(world_to_axial(furthest), -1)
	for world_o in origins:
		var d = GridManager.distance_map.get(world_to_axial(world_o), -1)
		if d > best_d:
			best_d = d
			furthest = world_o
	_last_spawn_axial = world_to_axial(furthest)

	# 3) instantiate tile at that hex
	var h = scene.instantiate() as HexagonTile
	h.axial_coords = axial
	h.position     = axial_to_world(axial)
	add_child(h)

	# 4) rebuild path‐map & test
	GridManager.register_tile(h)
	GridManager._rebuild_distance_map()
	if not GridManager.distance_map.has(_last_spawn_axial):
		# undo placement
		for dir in GridManager.DIRECTIONS:
			var nb = axial + dir
			if GridManager.tiles.has(nb):
				var nbr = GridManager.tiles[nb]
				if is_instance_valid(nbr) and nbr.neighbors.has(h):
					nbr.neighbors.erase(h)
		GridManager.deregister_tile(h)
		h.queue_free()
		return false

	# 5) wire neighbors + ripple
	for dir in GridManager.DIRECTIONS:
		var nax = axial + dir
		if GridManager.tiles.has(nax):
			var neigh = GridManager.tiles[nax]
			if is_instance_valid(neigh):
				h.neighbors.append(neigh)
				neigh.neighbors.append(h)
	if h.has_method("play_placement_ripple"):
		h.play_placement_ripple()

	return true

#——— HEX MATH UTILS ——————————————————————————————————————————————

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
	var q: float
	var r: float
	if hex_orientation == HexOrientation.POINTY:
		q = (2.0/3.0 * w.x) / hex_size
		r = ((-1.0/3.0 * w.x) + (sqrt(3)/3.0 * w.y)) / hex_size
	else:
		q = ((sqrt(3)/3.0 * w.x) - (1.0/3.0 * w.y)) / hex_size
		r = (2.0/3.0 * w.y) / hex_size
	var cube = cube_round(Vector3(q, -q - r, r))
	return cube_to_axial(cube)

func axial_to_world(a: Vector2) -> Vector2:
	if hex_orientation == HexOrientation.POINTY:
		return Vector2(
			hex_size * 1.5 * a.x,
			hex_size * sqrt(3) * (a.y + a.x * 0.5)
		)
	else:
		return Vector2(
			hex_size * sqrt(3) * (a.x + 0.5 * a.y),
			hex_size * 1.5 * a.y
		)
