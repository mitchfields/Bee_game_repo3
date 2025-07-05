# res://scripts/World.gd
extends Node2D
class_name World

@export var queen_scene: PackedScene
@export var hex_tile_scene: PackedScene
@export var hex_size: float = 50.0
@export var initial_spawn_distance: int = 8
@export var player_health: int = 20

signal placement_failed(scene_to_spawn: PackedScene)

const EMPTY_HEX: Vector2 = Vector2(-9999, -9999)

var _dragging_preview: Node2D    = null
var _dragging_scene: PackedScene = null
var _panning: bool               = false
var _last_spawn_axial: Vector2   = Vector2.ZERO
var initial_spawn_world: Vector2 = Vector2.ZERO

@onready var camera: Camera2D = $Camera2D
@onready var wave_manager: Node = $GameLayer/WaveManager

func _ready() -> void:
	randomize()
	var queen_instance: Node2D = _spawn_queen()
	if queen_instance != null:
		camera.make_current()
		camera.global_position = queen_instance.position
	initial_spawn_world = axial_to_world(Vector2(initial_spawn_distance, 0))
	wave_manager.connect("enemy_spawned", Callable(self, "_on_enemy_spawned"))

func _on_enemy_spawned(enemy: Node2D) -> void:
	if enemy.has_signal("hit_queen"):
		enemy.connect("hit_queen", Callable(self, "_on_enemy_hit_queen"))

func _on_enemy_hit_queen(_enemy: Node2D) -> void:
	player_health -= 1
	print("Player health: %d" % player_health)
	if player_health <= 0:
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.zoom *= Vector2(1.1, 1.1)
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.zoom *= Vector2(0.9, 0.9)
				return
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				_panning = true
				return
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = false
			return

	if _dragging_preview != null:
		if event is InputEventMouseMotion:
			_dragging_preview.global_position = get_global_mouse_position()
		elif event is InputEventMouseButton \
			 and event.button_index == MOUSE_BUTTON_LEFT \
			 and not event.pressed:
			var screen_height: float = get_viewport().get_visible_rect().size.y
			var did_place: bool = false
			if event.position.y < screen_height * 0.9:
				did_place = _spawn_hex(_dragging_scene)
			if did_place:
				_end_drag()
			else:
				_end_drag(true)
		return

	if _panning and event is InputEventMouseMotion:
		camera.global_position -= event.relative / camera.zoom
		return

func start_drag(scene_to_spawn: PackedScene) -> void:
	if _dragging_preview != null:
		_dragging_preview.queue_free()
	_dragging_scene   = scene_to_spawn
	_dragging_preview = scene_to_spawn.instantiate() as Node2D
	add_child(_dragging_preview)
	_dragging_preview.modulate = Color(1, 1, 1, 0.6)
	_dragging_preview.scale    = Vector2(0.8, 0.8)
	_dragging_preview.z_index  = 999

func _end_drag(failed: bool = false) -> void:
	if failed:
		emit_signal("placement_failed", _dragging_scene)
	if _dragging_preview != null:
		_dragging_preview.queue_free()
	_dragging_preview = null
	_dragging_scene   = null

func _spawn_queen() -> Node2D:
	if queen_scene == null:
		push_error("World.gd: queen_scene not assigned!")
		return null
	var q: Node2D = queen_scene.instantiate() as Node2D
	q.position = axial_to_world(Vector2.ZERO)
	add_child(q)
	return q

func _spawn_hex(scene_to_spawn: PackedScene) -> bool:
	# 1) pick clicked hex
	var mouse_pos: Vector2 = get_global_mouse_position()
	var clicked_axial: Vector2 = world_to_axial(mouse_pos)
	if clicked_axial == Vector2.ZERO:
		return false

	# 2) snap to nearest empty if occupied
	var place_axial: Vector2 = clicked_axial
	if GridManager.tiles.has(place_axial):
		var free_axial: Vector2 = _find_nearest_empty(place_axial)
		if free_axial == EMPTY_HEX:
			return false
		place_axial = free_axial

	# 3) path-block test: choose furthest spawn origin
	var origins: Array = wave_manager.cluster_origins.duplicate() as Array
	if origins.is_empty():
		origins.append(initial_spawn_world)
	var furthest_origin: Vector2 = origins[0] as Vector2
	var best_distance: int = -1
	for raw_origin in origins:
		var origin_vec: Vector2 = raw_origin as Vector2
		var raw_dist: Variant = GridManager.distance_map.get(world_to_axial(origin_vec), -1)
		var dist: int = int(raw_dist)
		if dist > best_distance:
			best_distance = dist
			furthest_origin = origin_vec
	_last_spawn_axial = world_to_axial(furthest_origin)

	# 4) instantiate & position
	var tile: HexagonTile = scene_to_spawn.instantiate() as HexagonTile
	tile.axial_coords = place_axial
	tile.position    = axial_to_world(place_axial)
	add_child(tile)

	# 5) register & link neighbors
	GridManager.register_tile(tile)
	for raw_dir in GridManager.DIRECTIONS:
		var dir: Vector2 = raw_dir as Vector2
		var n_axial: Vector2 = place_axial + dir
		if GridManager.tiles.has(n_axial):
			var nbr: HexagonTile = GridManager.tiles[n_axial] as HexagonTile
			tile.neighbors.append(nbr)
			nbr.neighbors.append(tile)
	if tile.has_method("play_placement_ripple"):
		tile.play_placement_ripple()

	# 6) rebuild & undo if path-blocked
	GridManager._rebuild_distance_map()
	if not GridManager.distance_map.has(_last_spawn_axial):
		for nbr in tile.neighbors:
			nbr.neighbors.erase(tile)
		tile.neighbors.clear()
		GridManager.deregister_tile(tile)
		tile.queue_free()
		return false

	return true

func _find_nearest_empty(start_axial: Vector2) -> Vector2:
	var visited: Dictionary = {}
	var queue: Array = [ start_axial ]
	visited[start_axial] = true
	while queue.size() > 0:
		var cur: Vector2 = queue.pop_front() as Vector2
		if not GridManager.tiles.has(cur) and cur != Vector2.ZERO:
			return cur
		for raw_dir in GridManager.DIRECTIONS:
			var dir: Vector2 = raw_dir as Vector2
			var nxt: Vector2 = cur + dir
			if not visited.has(nxt):
				visited[nxt] = true
				queue.append(nxt)
	return EMPTY_HEX

func axial_to_cube(a: Vector2) -> Vector3:
	return Vector3(a.x, -a.x - a.y, a.y)

func cube_to_axial(c: Vector3) -> Vector2:
	return Vector2(c.x, c.z)

func cube_round(c: Vector3) -> Vector3:
	var rx: float = round(c.x)
	var ry: float = round(c.y)
	var rz: float = round(c.z)
	var dx: float = abs(rx - c.x)
	var dy: float = abs(ry - c.y)
	var dz: float = abs(rz - c.z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector3(rx, ry, rz)

func world_to_axial(world: Vector2) -> Vector2:
	var q: float = (2.0 / 3.0) * world.x / hex_size
	var r: float = ((-1.0 / 3.0) * world.x + (sqrt(3)/3.0) * world.y) / hex_size
	var c: Vector3 = cube_round(Vector3(q, -q - r, r))
	return cube_to_axial(c)

func axial_to_world(a: Vector2) -> Vector2:
	var x: float = hex_size * (3.0/2.0 * a.x)
	var y: float = hex_size * ((sqrt(3)/2.0) * a.x + sqrt(3) * a.y)
	return Vector2(x, y)
