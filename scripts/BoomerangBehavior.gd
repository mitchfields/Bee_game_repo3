extends ProjectileBehavior
class_name BoomerangBehavior

@export var sprite: Texture2D
@export var max_distance: float = 300.0
var _origin: Vector2
var _returning: bool = false

func on_spawn(proj: Node2D, _pt: ProjectileType) -> void:
	_origin = proj.global_position
	_returning = false

func on_update(proj: Node2D, _pt: ProjectileType, _delta: float) -> void:
	var d = proj.global_position.distance_to(_origin)
	if not _returning and d >= max_distance:
		_returning = true
		proj.velocity = -proj.velocity

func on_hit(_proj: Node2D, _pt: ProjectileType, _target: Node) -> void:
	pass

func on_expire(_proj: Node2D, _pt: ProjectileType) -> void:
	pass

func get_sprite() -> Texture2D:
	return sprite
