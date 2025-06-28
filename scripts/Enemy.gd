extends CharacterBody2D

signal died
signal hit_queen

@export var speed: float = 120.0
var _world = null

func _ready() -> void:
	_world = get_tree().current_scene
	add_to_group("enemies")

func _physics_process(_delta: float) -> void:
	# 1) Flow‐field primary
	var my_ax = _world.world_to_axial(global_position)
	if GridManager.distance_map.has(my_ax):
		var best_d = INF
		var best_dir = Vector2.ZERO
		for dir in GridManager.DIRECTIONS:
			var nbr = my_ax + dir
			var d = GridManager.distance_map.get(nbr, INF)
			if d < best_d:
				best_d = d
				best_dir = dir
		if best_d < INF:
			var target = _world.axial_to_world(my_ax + best_dir)
			velocity = (target - global_position).normalized() * speed
			move_and_slide()
			return

	# 2) A* fallback
	var fallback = GridManager.find_path(my_ax, Vector2.ZERO)
	if fallback.size() > 0:
		var next_ax = fallback[0]
		var target = _world.axial_to_world(next_ax)
		velocity = (target - global_position).normalized() * speed
		move_and_slide()
		return

	# 3) No path → hit queen
	emit_signal("hit_queen")
	queue_free()

func die() -> void:
	emit_signal("died")
	queue_free()
