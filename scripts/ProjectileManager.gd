extends Node2D

@export var pool_size: int = 2000

var _free   : Array = []
var _in_use : Array = []

func _ready() -> void:
	# Pre-instance the pool
	for i in pool_size:
		var p = preload("res://scenes/Projectile.tscn").instantiate() as Node2D
		p.hide()
		p.set_process(false)
		p.connect("returned_to_pool", Callable(self, "_on_returned_to_pool"))
		add_child(p)
		_free.append(p)

# target can be a Node2D or a Vector2
func spawn(pt: ProjectileType, start_pos: Vector2, target) -> void:
	if _free.is_empty():
		return
	var p = _free.pop_back()
	_in_use.append(p)
	p.init(pt, start_pos, target)

func _on_returned_to_pool(p: Node2D) -> void:
	_in_use.erase(p)
	_free.append(p)
