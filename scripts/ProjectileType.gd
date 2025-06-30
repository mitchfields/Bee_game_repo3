extends Resource
class_name ProjectileType

@export var stats      : ProjectileStats
@export var behaviors : Array            = []
@export var texture   : Texture2D
@export var color     : Color            = Color(1,1,1)
@export var hit_radius: float            = 8.0   # pixels
