# res://scripts/GridManager.gd
extends Node
signal grid_changed

@export var max_search_radius: int = 100

var tiles: Dictionary        = {}   # axial_coord → Tile node
var distance_map: Dictionary = {}   # axial_coord → distance to Queen

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
	call_deferred("_rebuild_distance_map")

func register_tile(tile: Node2D) -> void:
	if not is_instance_valid(tile):
		return
	tiles[tile.axial_coords] = tile
	call_deferred("_rebuild_distance_map")

func deregister_tile(tile: Node2D) -> void:
	if is_instance_valid(tile):
		tiles.erase(tile.axial_coords)
	call_deferred("_rebuild_distance_map")

func _rebuild_distance_map() -> void:
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
	emit_signal("grid_changed")

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

	while open_set.size() > 0:
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
