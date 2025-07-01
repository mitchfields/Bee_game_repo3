# res://scripts/Turret.gd
extends "res://scripts/HexagonTile.gd"

signal shot_fired

@export_group("Firing")
@export var base_fire_rate:   float = 2    # seconds between shots
@export var attack_range:     float = 7.0  # in hex units
@export var magazine_size:    int   = 3
@export var reload_time:      float = 3.0  # seconds to reload

@export_group("Projectile Override (optional)")
@export var override_type: ProjectileType = null

@export_group("Projectile Defaults")
@export var default_speed:      float                   = 800.0
@export var default_damage:     int                     = 5
@export var default_lifetime:   float                   = 2.0
@export var default_behaviors:  Array[ProjectileBehavior] = [
	preload("res://scripts/StraightBehavior.gd").new()
]

# internal state
var _ammo:      int
var _cooldown:  float
var _reloading: bool  = false

# cache the pool autoload
@onready var _pm = get_node("/root/ProjectileManager")

func _ready() -> void:
	# When the turret is first spawned/scene-ready, treat it as placed
	on_place()

func on_place() -> void:
	_ammo      = magazine_size
	_cooldown  = 0.0
	_reloading = false
	set_process(true)

func on_remove() -> void:
	set_process(false)

func _process(delta: float) -> void:
	# Reload logic
	if _reloading:
		_cooldown -= delta
		if _cooldown <= 0.0:
			_ammo      = magazine_size
			_reloading = false
			# (silent reload)
	else:
		_cooldown -= delta
		if _cooldown <= 0.0:
			var target = _find_target()
			# (silent target check)
			if target:
				_shoot(target)
				_ammo -= 1
				if _ammo <= 0:
					_reloading = true
					_cooldown  = reload_time
				else:
					_cooldown  = base_fire_rate

func _find_target() -> Node2D:
	var world_r = attack_range * get_tree().current_scene.hex_size
	for e in get_tree().get_nodes_in_group("Enemies"):
		if global_position.distance_to(e.global_position) <= world_r:
			return e
	return null

func _build_projectile_type() -> ProjectileType:
	if override_type:
		var pt2 = override_type.duplicate()
		if pt2.behaviors == null:
			pt2.behaviors = []
		return pt2

	var pt = ProjectileType.new()
	pt.stats          = ProjectileStats.new()
	pt.stats.speed    = default_speed
	pt.stats.damage   = default_damage
	pt.stats.lifetime = default_lifetime
	pt.behaviors      = []
	for b in default_behaviors:
		pt.behaviors.append(b.duplicate())
	pt.hit_radius     = 8.0
	return pt

func _shoot(target: Node2D) -> void:
	var pt = _build_projectile_type()
	_pm.spawn(pt, global_position, target)
	emit_signal("shot_fired", target)
