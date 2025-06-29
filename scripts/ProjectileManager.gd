extends Node2D

@export var pool_size: int = 200
var _free = []
var _in_use = []

func _ready() -> void:
	for i in pool_size:
		var p = preload("res://scenes/Projectile.tscn").instantiate()
		add_child(p)
		p.hide()
		p.connect("returned_to_pool", Callable(self, "_on_returned"))
		_free.append(p)

func spawn(pt: ProjectileType, start: Vector2, target: Vector2) -> void:
	if _free.empty():
		return
	var p = _free.pop_back()
	_in_use.append(p)
	var dir = target - start
	p.init(pt, start, dir)

func _on_returned(p: Node) -> void:
	_in_use.erase(p)
	_free.append(p)
