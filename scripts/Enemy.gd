# res://scripts/Enemy.gd
extends CharacterBody2D

signal died
signal hit_queen

@export var speed:      float = 40.0
@export var max_health: int   = 10

var hp:    int       = 0
var _world: Node    = null

func _ready() -> void:
	# Cache a reference to your World
	_world = get_tree().current_scene
	# Ensure this enemy is visible to turrets
	add_to_group("Enemies")
	# Initialize health
	hp = max_health
	# If you have a ProgressBar child named "HealthBar", set it up
	if has_node("HealthBar"):
		var hb = $HealthBar as ProgressBar
		hb.min_value = 0
		hb.max_value = max_health
		hb.value     = hp

func _physics_process(_delta: float) -> void:
	# 1) Flow‐field primary movement
	var my_ax = _world.world_to_axial(global_position)
	if GridManager.distance_map.has(my_ax):
		var best_d = INF
		var best_dir = Vector2.ZERO
		for dir in GridManager.DIRECTIONS:
			var nbr = my_ax + dir
			var d = GridManager.distance_map.get(nbr, INF)
			if d < best_d:
				best_d   = d
				best_dir = dir
		if best_d < INF:
			var world_target = _world.axial_to_world(my_ax + best_dir)
			velocity = (world_target - global_position).normalized() * speed
			move_and_slide()
			return

	# 2) A* fallback movement
	var fallback = GridManager.find_path(my_ax, Vector2.ZERO)
	if fallback.size() > 0:
		var next_ax = fallback[0]
		var world_target = _world.axial_to_world(next_ax)
		velocity = (world_target - global_position).normalized() * speed
		move_and_slide()
		return

	# 3) No path → reach the queen
	emit_signal("hit_queen")
	queue_free()

func take_damage(amount: int) -> void:
	# Decrease HP and update the bar
	hp = max(hp - amount, 0)
	if has_node("HealthBar"):
		$HealthBar.value = hp
	# Die when empty
	if hp == 0:
		die()

func die() -> void:
	emit_signal("died", self)
	queue_free()
