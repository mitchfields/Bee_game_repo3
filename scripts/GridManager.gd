# res://scripts/GridManager.gd
extends Node

signal grid_changed

var tiles: Dictionary = {}
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

func register_tile(tile: Node2D) -> void:
	tiles[tile.axial_coords] = tile
	emit_signal("grid_changed")

func deregister_tile(tile: Node2D) -> void:
	tiles.erase(tile.axial_coords)
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

# A* with an optional skip list (do not mutate tiles)
func find_path(start: Vector2, goal: Vector2, skip_tiles: Array = []) -> Array:
	var open_set  = [ start ]
	var came_from = {}
	var g_score   = { start: 0.0 }
	var f_score   = { start: _heuristic(start, goal) }

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
			# skip if truly occupied or in our ephemeral skip list
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
