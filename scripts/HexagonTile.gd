# res://scripts/HexagonTile.gd
extends Node2D
class_name HexagonTile

@export var axial_coords: Vector2 = Vector2.ZERO
@export var ripple_radius: int    = 10
var neighbors: Array              = []

var _selected: bool               = false
@export var selection_tint: Color = Color(1.0, 1.0, 0.0, 0.5)

# — hooks for subclasses —
func on_place() -> void: pass
func on_remove() -> void: pass
func on_connect(_tile) -> void: pass
func on_hover() -> void: pass
func apply_stats(_projectile) -> void: pass

func _ready() -> void:
	scale = Vector2.ONE
	rotation_degrees = 0.0
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited",  Callable(self, "_on_mouse_exited"))

func _on_mouse_entered() -> void:
	on_hover()
	if not _selected:
		modulate = Color(1.0, 1.0, 1.0, 0.8)

func _on_mouse_exited() -> void:
	if not _selected:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_selected(on: bool) -> void:
	_selected = on
	if on:
		modulate = selection_tint
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func play_placement_ripple() -> void:
	_create_ball_bounce()
	var layers: Array = _bfs_layers(ripple_radius)
	var max_ring: int = layers.size() - 1
	for i in range(1, layers.size()):
		await get_tree().create_timer(i * 0.05).timeout
		var intensity: float = 1.0
		if max_ring > 0:
			intensity = 1.0 - float(i) / float(max_ring)
		var ring: Array = layers[i]
		for tile in ring:
			tile._create_ripple_tween_with_falloff(intensity)

func _create_ball_bounce() -> void:
	var peaks: Array    = [1.4, 1.12, 1.05]
	var durations: Array = [0.1, 0.08, 0.06]
	for idx in range(peaks.size()):
		var p: float = peaks[idx]
		var d: float = durations[idx]
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(p,p), d)\
		  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "scale", Vector2.ONE, d)\
		  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _create_ripple_tween_with_falloff(intensity: float) -> void:
	var base_trough: float = 0.85
	var trough_scale: float = clamp(1.0 - (1.0 - base_trough) * intensity, base_trough, 1.0)
	trough_scale *= (0.9 + randf() * 0.1)
	var dur: float = lerp(0.1, 0.2, 1.0 - intensity)
	var rot: float = (randf() * 2.0 - 1.0) * 15.0 * intensity

	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(trough_scale, trough_scale), dur)\
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", rot, dur)\
	  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, dur)\
	  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", 0.0, dur)\
	  .set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _bfs_layers(max_radius: int) -> Array:
	var visited: Dictionary = {}
	var frontier: Array = [self]
	visited[self] = true
	var layers: Array = []
	var depth: int = 0
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
