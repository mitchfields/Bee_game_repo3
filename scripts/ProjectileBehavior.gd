extends Resource
class_name ProjectileBehavior

# Called once when the projectile spawns
func on_spawn(proj: Node2D, pt: ProjectileType) -> void: pass

# Called every frame
func on_update(proj: Node2D, pt: ProjectileType, delta: float) -> void: pass

# Called when hitting an enemy
func on_hit(proj: Node2D, pt: ProjectileType, target: Node) -> void: pass

# Called when lifetime expires
func on_expire(proj: Node2D, pt: ProjectileType) -> void: pass
