extends Resource
class_name ProjectileBehavior

# Called once when the projectile spawns
func on_spawn(_proj: Node2D, _pt: ProjectileType) -> void:
	pass

# Called every frame
func on_update(_proj: Node2D, _pt: ProjectileType, _delta: float) -> void:
	pass

# Called when hitting an enemy
func on_hit(_proj: Node2D, _pt: ProjectileType, _target: Node) -> void:
	pass

# Called when lifetime expires
func on_expire(_proj: Node2D, _pt: ProjectileType) -> void:
	pass

# New hook to supply a sprite for this behavior
func get_sprite() -> Texture2D:
	return null
