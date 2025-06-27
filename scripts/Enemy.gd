# res://scripts/Enemy.gd
extends CharacterBody2D

signal died
signal hit_queen

@export var speed: float = 120.0

# holds a list of axial coords (Vector2) to follow
var path: Array = []
var _idx: int   = 0
var _world      = null

func _ready() -> void:
	_world = get_tree().current_scene
	# re-plan whenever walls change
	GridManager.connect("grid_changed", Callable(self, "_on_grid_changed"))

func set_path(p) -> void:
	# accept any Array of Vector2, no type mismatch
	path = p.duplicate()
	_idx = 0

func _on_grid_changed() -> void:
	# recompute from current pos to queen at (0,0)
	var my_axial = _world.world_to_axial(global_position)
	var new_path = GridManager.find_path(my_axial, Vector2.ZERO)
	if new_path.size() > 0:
		set_path(new_path)

func _physics_process(delta: float) -> void:
	if _idx < path.size():
		var target = _world.axial_to_world(path[_idx])
		var dir    = (target - global_position).normalized()
		velocity   = dir * speed
		move_and_slide()
		if global_position.distance_to(target) < speed * delta:
			_idx += 1
	else:
		emit_signal("hit_queen")
		queue_free()

func die() -> void:
	emit_signal("died")
	queue_free()
