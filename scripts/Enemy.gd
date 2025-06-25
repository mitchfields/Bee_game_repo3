# res://scripts/Enemy.gd
extends CharacterBody2D

@export var speed     : float = 120.0
@export var gold_drop : int   = 1
@export var damage    : int   = 1

var _path       : Array     = []
var _path_index : int       = 0

@onready var world = get_tree().current_scene   # assumes World.gd is the root

func _ready() -> void:
	# 1) Convert spawn pos → axial
	var start_axial = world.world_to_axial(global_position)
	# 2) Queen is always at axial (0,0)
	var goal_axial = Vector2.ZERO
	# 3) Ask GridManager for path
	_path = GridManager.find_path(start_axial, goal_axial)
	_path_index = 0

func _physics_process(delta: float) -> void:
	if _path_index < _path.size():
		# move toward the next cell center
		var target_pos = world.axial_to_world(_path[_path_index])
		var direction  = (target_pos - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		# if close enough, step to next
		if global_position.distance_to(target_pos) < speed * delta:
			_path_index += 1
	else:
		# reached the Queen
		emit_signal("hit_queen")   # connect this to WaveManager
		queue_free()
