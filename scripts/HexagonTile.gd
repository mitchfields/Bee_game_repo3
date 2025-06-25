# res://scripts/HexagonTile.gd
extends Node2D

@export var axial_coords: Vector2
@export var ripple_radius: int = 10
var neighbors: Array = []

func _ready() -> void:
	scale = Vector2.ONE
	rotation_degrees = 0

func play_placement_ripple() -> void:
	# 1) Punchy 3-bounce on the placed tile
	_create_ball_bounce()

	# 2) Ripple outwards with falloff, random rotation & scale-down variation
	var layers = _bfs_layers(ripple_radius)
	var max_ring = layers.size() - 1
	for ring_index in range(1, layers.size()):
		await get_tree().create_timer(ring_index * 0.05).timeout
		var intensity = 1.0
		if max_ring > 0:
			intensity = 1.0 - float(ring_index) / float(max_ring)
		for tile in layers[ring_index]:
			tile._create_ripple_tween_with_falloff(intensity)

func _create_ball_bounce() -> void:
	var peaks     = [1.4, 1.12, 1.05]
	var durations = [0.1,  0.08,  0.06]
	var tw = create_tween()
	for i in range(peaks.size()):
		var target = Vector2.ONE * peaks[i]
		var d = durations[i]
		tw.tween_property(self, "scale", target, d) \
		  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE, d) \
		  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _create_ripple_tween_with_falloff(intensity: float) -> void:
	# compute a scale-down trough based on intensity, clamped to not exceed original scale
	var base_trough = 0.85                     # minimum scale at intensity=1
	var trough_scale = 1.0 - (1.0 - base_trough) * intensity
	# add slight randomness around the trough
	var rand_factor = 0.9 + randf() * 0.1      # between 0.9 and 1.0 to avoid upscaling
	trough_scale = clamp(trough_scale * rand_factor, base_trough, 1.0)

	# durations: closer rings animate faster
	var min_dur = 0.1
	var max_dur = 0.2
	var dur = min_dur + (1.0 - intensity) * (max_dur - min_dur)

	# random rotation up to ±15° × intensity
	var max_rot = 15.0
	var rot = (randf() * 2.0 - 1.0) * max_rot * intensity

	# tween down + rotate
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(trough_scale, trough_scale), dur) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", rot, dur) \
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# tween back up + straighten
	tw.tween_property(self, "scale", Vector2.ONE, dur) \
	  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", 0, dur) \
	  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _bfs_layers(max_radius: int) -> Array:
	var visited = { self: true }
	var frontier = [ self ]
	var layers: Array = []
	var depth = 0
	while frontier.size() > 0 and depth <= max_radius:
		layers.append(frontier.duplicate())
		var next_frontier: Array = []
		for t in frontier:
			for n in t.neighbors:
				if not visited.has(n):
					visited[n] = true
					next_frontier.append(n)
		frontier = next_frontier
		depth += 1
	return layers
