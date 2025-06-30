# res://scripts/Enemy.gd
extends CharacterBody2D

signal died
signal hit_queen

@export var speed:      float = 40.0
@export var max_health: int   = 10

var hp:    int      = 0
var _world: Node2D = null

func _ready() -> void:
	_world = get_tree().current_scene
	add_to_group("Enemies")
	hp = max_health
	if has_node("HealthBar"):
		var hb = $HealthBar as ProgressBar
		hb.min_value = 0
		hb.max_value = max_health
		hb.value     = hp

func _physics_process(_delta: float) -> void:
	# *** NEW: if we’re already on the Queen’s hex, kill ourselves immediately ***
	var my_ax = _world.world_to_axial(global_position)
	if my_ax == Vector2.ZERO:
		emit_signal("hit_queen", self)
		queue_free()
		return

	# 1) Flow‐field primary
	if GridManager.distance_map.has(my_ax):
		var best_d   = INF
		var best_dir = Vector2.ZERO
		for dir in GridManager.DIRECTIONS:
			var nbr = my_ax + dir
			var d   = GridManager.distance_map.get(nbr, INF)
			if d < best_d:
				best_d   = d
				best_dir = dir
		if best_d < INF:
			var tgt = _world.axial_to_world(my_ax + best_dir)
			velocity = (tgt - global_position).normalized() * speed
			move_and_slide()
			return

	# 2) A* fallback
	var fallback = GridManager.find_path(my_ax, Vector2.ZERO)
	if fallback.size() > 0:
		var next_ax = fallback[0]
		var tgt     = _world.axial_to_world(next_ax)
		velocity = (tgt - global_position).normalized() * speed
		move_and_slide()
		return

	# 3) (Shouldn’t happen) but just in case: no path → hit queen
	emit_signal("hit_queen", self)
	queue_free()

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	if has_node("HealthBar"):
		$HealthBar.value = hp
	if hp == 0:
		die()

func die() -> void:
	emit_signal("died", self)
	queue_free()
