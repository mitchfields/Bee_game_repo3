extends Resource
class_name ProjectileType

@export var stats      : ProjectileStats
@export var behaviors : Array[ProjectileBehavior] = []

# visuals
@export var texture   : Texture2D
@export var color     : Color = Color(1,1,1)
