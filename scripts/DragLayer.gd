# res://scripts/DragLayer.gd
extends Control

var dragging_slot = null
var origin_shop = null
var origin_index = -1

func start_drag(slot, shop_manager, index):
	dragging_slot = slot
	origin_shop = shop_manager
	origin_index = index
	slot.get_parent().remove_child(slot)
	add_child(slot)
	slot.modulate = Color(1,1,1,0.8)

func _unhandled_input(event):
	if dragging_slot == null:
		return
	if event is InputEventMouseMotion:
		dragging_slot.global_position = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var screen_h = get_viewport().get_visible_rect().size.y
		var placed = false
		if event.position.y < screen_h * 0.9:
			placed = get_tree().current_scene._spawn_hex(dragging_slot.scene_to_spawn)
		if placed:
			origin_shop.on_slot_dragged_off(dragging_slot)
			dragging_slot.queue_free()
		else:
			origin_shop.on_slot_returned_back(dragging_slot, origin_index)
		dragging_slot = null
		origin_shop = null
		origin_index = -1
		get_tree().set_input_as_handled()
