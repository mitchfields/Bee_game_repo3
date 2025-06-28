# res://scripts/GridManager.gd
extends Node

signal grid_changed

@export var max_search_radius: int = 30      # BFS max radius for flow‐field
@export var max_search_iterations: int = 10000  # absolute A* step limit

var tiles: Dictionary = {}
var distance_map: Dictionary = {}

const DIRECTIONS = [
	Vector2(1, 0),
	Vector2(1, -1),
	Vector2(0, -1),
	Vector2(-1, 0),
	Vector2(-1, 1),
	Vector2(0, 1),
]

func _ready() -> void:
	tiles.clear()
	# only rebuild on register/deregister

func can_place_tile(axial: Vector2, world_origins: Array) -> bool:
	var skip_tiles = [ axial ]
	for world_o in world_origins:
		var origin_axial = get_tree().current_scene.world_to_axial(world_o)
		var path = find_path(origin_axial, Vector2.ZERO, skip_tiles)
		if path.size() == 0:
			return false
	return true

func rebuild_distance_map() -> void:
	distance_map.clear()
	distance_map[Vector2.ZERO] = 0
	var frontier = [ Vector2.ZERO ]
	var dist = 0
	while frontier.size() > 0 and dist < max_search_radius:
		var next_frontier = []
		for cell in frontier:
			for dir in DIRECTIONS:
				var nbr = cell + dir
				if tiles.has(nbr) or distance_map.has(nbr):
					continue
				distance_map[nbr] = dist + 1
				next_frontier.append(nbr)
		frontier = next_frontier
		dist += 1

func register_tile(tile: Node2D) -> void:
	tiles[tile.axial_coords] = tile
	rebuild_distance_map()
	emit_signal("grid_changed")

func deregister_tile(tile: Node2D) -> void:
	tiles.erase(tile.axial_coords)
	rebuild_distance_map()
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
	var open_set: Array = [ start ]
	var came_from: Dictionary = {}
	var g_score: Dictionary = { start: 0.0 }
	var f_score: Dictionary = { start: _heuristic(start, goal) }

	var iterations = 0
	while open_set.size() > 0:
		iterations += 1
		if iterations > max_search_iterations:
			push_warning("A* aborted after %d iterations" % max_search_iterations)
			return []  # treat as no path

		# pick lowest f_score
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
	return []  # no valid path
