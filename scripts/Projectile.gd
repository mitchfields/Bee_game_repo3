# res://scenes/Projectile.gd
extends Node2D

signal returned_to_pool

var velocity : Vector2
var _type    : ProjectileType
var _time    : float = 0.0

func init(pt: ProjectileType, start_pos: Vector2, dir: Vector2) -> void:
	_type = pt
	global_position = start_pos
	_time = 0.0

	# configure visuals
	$Sprite.texture = pt.texture
	$Sprite.modulate = pt.color

	# compute velocity once
	velocity = dir.normalized() * pt.stats.speed

	show()
	set_process(true)
	# behaviors on_spawn
	for beh in pt.behaviors:
		beh.on_spawn(self, pt)

func _process(delta: float) -> void:
	# move
	global_position += velocity * delta

	# update behaviors
	for beh in _type.behaviors:
		beh.on_update(self, _type, delta)

	# lifetime check
	_time += delta
	if _time >= _type.stats.lifetime:
		_expire()
		return

	# --- Godot 4 style point query ---
	var params = PhysicsPointQueryParameters2D.new()
	params.position = global_position
	params.collide_with_bodies = true
	params.collide_with_areas = true
	# max_results = 1 since we only care about the first hit
	var results = get_world_2d().direct_space_state.intersect_point(params, 1)
	if results.size() > 0:
		var hit = results[0].collider
		if hit.is_in_group("Enemies"):
			for beh in _type.behaviors:
				beh.on_hit(self, _type, hit)
			hit.take_damage(_type.stats.damage)
			_return_to_pool()

func _expire() -> void:
	for beh in _type.behaviors:
		beh.on_expire(self, _type)
	_return_to_pool()

func _return_to_pool() -> void:
	set_process(false)
	hide()
	emit_signal("returned_to_pool", self)
