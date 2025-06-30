extends Node2D

signal returned_to_pool

var velocity     : Vector2        = Vector2.ZERO
var _type        : ProjectileType = null
var _behaviors   : Array          = []
var _time        : float          = 0.0
var _target_node : Node2D
var _target_pos  : Vector2        = Vector2.ZERO

func init(pt: ProjectileType, start_pos: Vector2, target) -> void:
	_type = pt
	global_position = start_pos
	_time = 0.0

	# --- Resolve the target (Node2D or raw Vector2) ---
	if typeof(target) == TYPE_OBJECT and target is Node2D:
		_target_node = target
		_target_pos  = target.global_position
	else:
		_target_node = null
		_target_pos  = target as Vector2

	# --- Clear only the *dynamic* sprites we added last time ---
	for child in get_children():
		# we name dynamic sprites "dyn_#"
		if child is Sprite2D and child.name.begins_with("dyn_"):
			child.queue_free()

	# --- Add one Sprite2D per behavior, if it has art ---
	var layer = 0
	for beh in _type.behaviors:
		if beh.has_method("get_sprite"):
			var tex = beh.get_sprite()
			if tex:
				var s = Sprite2D.new()
				s.name   = "dyn_%d" % layer
				s.texture = tex
				s.z_index = layer
				add_child(s)
				layer += 1

	# --- Fallback to your built-in Sprite2D if no behaviors gave art ---
	if layer == 0 and _type.texture and has_node("Sprite2D"):
		var base = $Sprite2D
		base.texture  = _type.texture
		base.modulate = _type.color
		base.show()

	# --- Face and propel toward the target ---
	var dir = (_target_pos - start_pos).normalized()
	velocity = dir * (_type.stats.speed if _type.stats else 0.0)
	rotation = dir.angle()

	# --- Clone and run on_spawn for each behavior ---
	_behaviors.clear()
	for b in _type.behaviors:
		_behaviors.append(b.duplicate())
	for b in _behaviors:
		b.on_spawn(self, _type)

	show()
	set_process(true)


func _process(delta: float) -> void:
	if _type == null:
		return

	# Move
	global_position += velocity * delta

	# Behaviors
	for b in _behaviors:
		b.on_update(self, _type, delta)

	# Lifetime expire
	_time += delta
	var life = _type.stats.lifetime if _type.stats else 0.0
	if _time >= life:
		_return_to_pool()
		return

	# Manual, single-target hit test
	if _target_node and is_instance_valid(_target_node):
		if global_position.distance_to(_target_pos) <= _type.hit_radius:
			for b in _behaviors:
				b.on_hit(self, _type, _target_node)
			if _target_node.has_method("take_damage"):
				_target_node.take_damage(_type.stats.damage if _type.stats else 0)
			_return_to_pool()
	else:
		# no node (or died)—expire when you reach the point
		if global_position.distance_to(_target_pos) <= _type.hit_radius:
			_return_to_pool()


func _return_to_pool() -> void:
	hide()
	set_process(false)
	emit_signal("returned_to_pool", self)
