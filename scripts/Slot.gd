# res://Slot.gd
extends TextureButton

@export var scene_to_spawn: PackedScene

func _ready():
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	# ask DragLayer to pull this node out
	var shop = get_parent() as ShopManager
	var idx  = shop.slots.find(self)
	get_node("/root/World/UI/DragLayer").start_drag(self, shop, idx)
