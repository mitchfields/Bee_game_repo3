# res://scripts/GridManager.gd
extends Node

signal grid_changed

@export var max_search_radius: int     = 30      # BFS max radius for flow‐field
@export var max_search_iterations: int = 10000  # A* step limit

var tiles: Dictionary        = {}   # axial_coord → Tile Node
var distance_map: Dictionary = {}   # axial_coord → steps to Queen
var _pending_full_rebuild: bool = false

const DIRECTIONS = [
	Vector2( 1,  0),
	Vector2( 1, -1),
	Vector2( 0, -1),
	Vector2(-1,  0),
	Vector2(-1,  1),
	Vector2( 0,  1),
]

func _ready() -> void:
	tiles.clear()
	rebuild_distance_map()
	emit_signal("grid_changed")

func _deferred_full_rebuild() -> void:
	_pending_full_rebuild = false
	rebuild_distance_map()
	emit_signal("grid_changed")

#— unchanged A* veto
func can_place_tile(axial: Vector2, world_origins: Array) -> bool:
	var skip_tiles = [ axial ]
	for world_o in world_origins:
		var origin_axial = get_tree().current_scene.world_to_axial(world_o)
		var path = find_path(origin_axial, Vector2.ZERO, skip_tiles)
		if path.is_empty():
			return false
	return true

#— full rebuild at startup 
func rebuild_distance_map() -> void:
	distance_map.clear()
	distance_map[Vector2.ZERO] = 0
	var frontier = [ Vector2.ZERO ]
	var dist     = 0
	while frontier.size() > 0 and dist < max_search_radius:
		var next_frontier: Array = []
		for cell in frontier:
			for dir in DIRECTIONS:
				var nbr = cell + dir
				if tiles.has(nbr) or distance_map.has(nbr):
					continue
				distance_map[nbr] = dist + 1
				next_frontier.append(nbr)
		frontier = next_frontier
		dist += 1

#— incremental updates in lieu of full rebuilds 
func register_tile(tile: Node2D) -> void:
	tiles[tile.axial_coords] = tile
	_update_distance_on_block(tile.axial_coords)
	emit_signal("grid_changed")

func deregister_tile(tile: HexagonTile) -> void:
	# 1) Clean up neighbor links so no one holds a reference to this freed tile
	for nb in tile.neighbors:
		if is_instance_valid(nb):
			nb.neighbors.erase(tile)
	tile.neighbors.clear()

	# 2) Remove from grid & update distance‐field
	tiles.erase(tile.axial_coords)
	_update_distance_on_unblock(tile.axial_coords)
	emit_signal("grid_changed")

#— incremental “block” update 
func _update_distance_on_block(blocked: Vector2) -> void:
	if blocked == Vector2.ZERO:
		return
	distance_map.erase(blocked)
	var queue: Array = []
	var in_queue: Dictionary = {}
	for dir in DIRECTIONS:
		var nbr = blocked + dir
		if distance_map.has(nbr):
			queue.append(nbr); in_queue[nbr] = true

	var processed = 0
	var max_proc = tiles.size() + distance_map.size() + 50
	while queue.size() > 0 and processed < max_proc:
		processed += 1
		var cell = queue.pop_front()
		in_queue.erase(cell)
		if cell == Vector2.ZERO:
			continue
		if tiles.has(cell):
			distance_map.erase(cell)
			continue

		var best = INF
		for dir in DIRECTIONS:
			var adj = cell + dir
			if distance_map.has(adj):
				best = min(best, distance_map[adj] + 1)

		var had_old = distance_map.has(cell)
		var old_val = distance_map[cell] if had_old else INF

		if best == INF:
			if had_old:
				distance_map.erase(cell)
				for dir in DIRECTIONS:
					var n2 = cell + dir
					if distance_map.has(n2) and not in_queue.has(n2):
						queue.append(n2); in_queue[n2] = true
		else:
			if not had_old or best != old_val:
				distance_map[cell] = best
				for dir in DIRECTIONS:
					var n2 = cell + dir
					if not tiles.has(n2) and not in_queue.has(n2):
						queue.append(n2); in_queue[n2] = true

	if processed >= max_proc and not _pending_full_rebuild:
		push_warning("Block‐update hit limit; deferring full rebuild.")
		_pending_full_rebuild = true
		call_deferred("_deferred_full_rebuild")

#— incremental “unblock” update 
func _update_distance_on_unblock(freed: Vector2) -> void:
	if freed == Vector2.ZERO:
		return
	var best = INF
	for dir in DIRECTIONS:
		var nbr = freed + dir
		if distance_map.has(nbr):
			best = min(best, distance_map[nbr] + 1)
	if best == INF:
		return

	distance_map[freed] = best
	var queue: Array = [ freed ]
	var in_queue: Dictionary = { freed:true }
	var processed = 0
	var max_proc = tiles.size() + distance_map.size() + 50

	while queue.size() > 0 and processed < max_proc:
		processed += 1
		var cell = queue.pop_front()
		in_queue.erase(cell)
		if cell == Vector2.ZERO:
			continue

		var d = distance_map[cell]
		for dir in DIRECTIONS:
			var nbr = cell + dir
			if tiles.has(nbr):
				continue
			var old_dist = distance_map[nbr] if distance_map.has(nbr) else INF
			if d + 1 < old_dist:
				distance_map[nbr] = d + 1
				if not in_queue.has(nbr):
					queue.append(nbr); in_queue[nbr] = true

	if processed >= max_proc and not _pending_full_rebuild:
		push_warning("Unblock‐update hit limit; deferring full rebuild.")
		_pending_full_rebuild = true
		call_deferred("_deferred_full_rebuild")

#— A* pathfinding (unchanged) 
func _heuristic(a: Vector2, b: Vector2) -> float:
	return (abs(a.x - b.x)
		  + abs(a.x + a.y - b.x - b.y)
		  + abs(a.y - b.y)) * 0.5

func _reconstruct(came_from: Dictionary, current: Vector2) -> Array:
	var path = [ current ]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path

func find_path(start: Vector2, goal: Vector2, skip_tiles: Array = []) -> Array:
	var open_set: Array      = [ start ]
	var came_from: Dictionary = {}
	var g_score: Dictionary   = { start: 0.0 }
	var f_score: Dictionary   = { start: _heuristic(start, goal) }

	var iterations = 0
	while open_set.size() > 0:
		iterations += 1
		if iterations > max_search_iterations:
			push_warning("A* aborted after %d iterations" % max_search_iterations)
			return []

		var current = open_set[0]
		for n in open_set:
			if f_score[n] < f_score[current]:
				current = n
		open_set.erase(current)

		if current == goal:
			return _reconstruct(came_from, current)

		for dir in DIRECTIONS:
			var neighbor = current + dir
			if tiles.has(neighbor) or skip_tiles.has(neighbor):
				continue
			var tentative = g_score[current] + 1.0
			if not g_score.has(neighbor) or tentative < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor]    = tentative
				f_score[neighbor]    = tentative + _heuristic(neighbor, goal)
				if neighbor not in open_set:
					open_set.append(neighbor)
	return []
