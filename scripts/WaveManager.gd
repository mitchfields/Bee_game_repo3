# res://scripts/WaveManager.gd
extends Node2D

signal wave_started(wave_number)
signal enemy_spawned(alive_count, max_count)
signal enemy_died(enemy, alive_count)
signal enemy_hit_queen(enemy, alive_count)

@export var enemy_scenes: Array[PackedScene] = []
@export var base_count: int                 = 5
@export var increment_per_wave: int         = 2
@export var spawn_interval: float           = 0.5

var wave_number: int = 0
var alive_count: int = 0
var max_alive:   int = 0
var spawning:    bool = false

func start_wave() -> void:
	if spawning:
		return
	wave_number += 1
	alive_count = 0
	max_alive   = 0
	spawning    = true
	emit_signal("wave_started", wave_number)
	_spawn_wave()

func _spawn_wave() -> void:
	var count = base_count + (wave_number - 1) * increment_per_wave
	for i in range(count):
		var scene = enemy_scenes[randi() % enemy_scenes.size()]
		var enemy = scene.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = _random_spawn_pos()
		# Bind the enemy instance into the Callable directly
		enemy.connect("died",      Callable(self, "_on_enemy_died").bind(enemy))
		enemy.connect("hit_queen", Callable(self, "_on_enemy_hit_queen").bind(enemy))
		alive_count += 1
		max_alive   += 1
		emit_signal("enemy_spawned", alive_count, max_alive)
		await get_tree().create_timer(spawn_interval).timeout
	spawning = false

func _random_spawn_pos() -> Vector2:
	var angle = randf() * TAU
	var radius = 600
	return get_parent().global_position + Vector2(cos(angle), sin(angle)) * radius

func _on_enemy_died(enemy: Node) -> void:
	alive_count -= 1
	emit_signal("enemy_died", enemy, alive_count)
	_check_wave_end()

func _on_enemy_hit_queen(enemy: Node) -> void:
	alive_count -= 1
	emit_signal("enemy_hit_queen", enemy, alive_count)
	_check_wave_end()

func _check_wave_end() -> void:
	if not spawning and alive_count <= 0:
		print("Wave %d complete!" % wave_number)
