extends ProjectileBehavior
class_name WobbleBehavior

@export var sprite: Texture2D
@export var amplitude: float = 5.0
@export var frequency: float = 10.0
var _t: float = 0.0

func on_spawn(_proj: Node2D, _pt: ProjectileType) -> void:
	pass

func on_update(proj: Node2D, _pt: ProjectileType, delta: float) -> void:
	_t += delta * frequency
	var offset = Vector2(sin(_t), cos(_t)) * amplitude * delta
	proj.position += offset

func on_hit(_proj: Node2D, _pt: ProjectileType, _target: Node) -> void:
	pass

func on_expire(_proj: Node2D, _pt: ProjectileType) -> void:
	pass

func get_sprite() -> Texture2D:
	return sprite
