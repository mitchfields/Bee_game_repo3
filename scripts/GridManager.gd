extends Node

var tiles: Dictionary = {}

func register_tile(tile):
	tiles[tile.axial_coords] = tile
	_connect_neighbors(tile)
	tile.play_placement_ripple()

func _connect_neighbors(tile):
	var dirs = [
		Vector2( 1,  0), Vector2( 0,  1), Vector2(-1,  1),
		Vector2(-1,  0), Vector2( 0, -1), Vector2( 1, -1)
	]
	for d in dirs:
		var pos = tile.axial_coords + d
		if tiles.has(pos):
			var other = tiles[pos]
			tile.neighbors.append(other)
			other.neighbors.append(tile)
