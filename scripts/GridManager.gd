# res://scripts/GridManager.gd
extends Node

# Stores placed tiles by axial coord
var tiles: Dictionary = {}

# Six axial neighbor steps
const DIRECTIONS: Array = [
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
	var coord: Vector2 = tile.axial_coords
	tiles[coord] = tile
	# Link neighbors for ripple (optional)
	if not tile.neighbors:
		tile.neighbors = []
	for dir in DIRECTIONS:
		var nc = coord + dir
		if tiles.has(nc):
			var n = tiles[nc]
			if not tile.neighbors.has(n):
				tile.neighbors.append(n)
			if not n.neighbors.has(tile):
				n.neighbors.append(tile)

# Heuristic: hex‐grid “Manhattan” distance
func _heuristic(a: Vector2, b: Vector2) -> float:
	return (abs(a.x - b.x)
		  + abs(a.x + a.y - b.x - b.y)
		  + abs(a.y - b.y)) * 0.5

# Reconstruct path
func _reconstruct(came_from: Dictionary, current: Vector2) -> Array:
	var path = [ current ]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path

# A* search on the axial grid
func find_path(start: Vector2, goal: Vector2) -> Array:
	var open_set = [ start ]
	var came_from = {}
	var g_score = { start: 0.0 }
	var f_score = { start: _heuristic(start, goal) }

	while open_set.size() > 0:
		# pick lowest‐f node manually
		var current = open_set[0]
		for node in open_set:
			if f_score[node] < f_score[current]:
				current = node
		open_set.erase(current)

		if current == goal:
			return _reconstruct(came_from, current)

		for dir in DIRECTIONS:
			var neighbor = current + dir
			# skip walls (unregistered)
			if not tiles.has(neighbor):
				continue
			var tentative = g_score[current] + 1
			if not g_score.has(neighbor) or tentative < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative
				f_score[neighbor] = tentative + _heuristic(neighbor, goal)
				if neighbor not in open_set:
					open_set.append(neighbor)
	return []  # no path found
