# DragLayer.gd
extends Node

var shop_layer: Node = null
var dragging_slot: Node = null

func _ready() -> void:
	# pick whichever exists
	shop_layer = get_node_or_null("ShopLayer")
	if shop_layer == null:
		shop_layer = get_node_or_null("ShopBar")
	if shop_layer == null:
		push_error("DragLayer.gd: neither ShopLayer nor ShopBar found!")

func start_drag(slot: Node) -> void:
	dragging_slot = slot
	shop_layer.remove_child(slot)
	add_child(slot)
	slot.modulate = Color(1,1,1,0.6)

func _unhandled_input(event: InputEvent) -> void:
	if dragging_slot == null:
		return
	if event is InputEventMouseMotion:
		dragging_slot.global_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var placed = get_tree().current_scene._spawn_hex(dragging_slot.scene_to_spawn)
		if not placed:
			# return to shop
			remove_child(dragging_slot)
			shop_layer.add_child(dragging_slot)
		dragging_slot = null
		get_tree().set_input_as_handled()
